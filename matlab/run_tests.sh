#!/usr/bin/env bash
#
# Run the SPM unit test suite against a container image, one test file per
# container, with a per-test timeout.
#
# Why not just "docker run <image> test"?
#   "docker run <image> test" runs the whole suite in a single MATLAB Runtime
#   session. If one test opens a figure (or otherwise touches graphics) the
#   headless container blocks forever and the whole run is lost with no clue
#   about which test did it. Running each test file in its own container with a
#   timeout turns that hang into a labelled TIMEOUT line, which is what you need
#   when hunting graphics-related failures.
#
# Usage:
#   ./run_tests.sh                                  # published latest image
#   ./run_tests.sh spm-local                        # a locally built image
#   ./run_tests.sh spm-local test_spm_mesh_area     # resume from this test
#   ./run_tests.sh spm-local "" 600                 # 600 s timeout per test
#
# Optional test data (some tests are skipped without it):
#   SPM_TESTS_DATA=/path/to/spm-tests-data ./run_tests.sh
#
# Optional Markdown summary (used by CI to populate the job summary):
#   SUMMARY_FILE=summary.md ./run_tests.sh
#
# Optional: restrict the run to specific test files (space or comma separated).
# Note this is different from START_FROM, which resumes and then runs the rest:
#   ONLY_TESTS="test_spm_plot_ci test_spm_run_dcm_bms" ./run_tests.sh
#
set -uo pipefail

IMAGE="${1:-ghcr.io/spm/spm-docker:docker-matlab-latest}"
START_FROM="${2:-}"        # resume: skip every test before this one
TIMEOUT_SECS="${3:-300}"   # seconds before a hanging container is killed
LOG="spm_test_results_$(date +%Y%m%d_%H%M%S).log"

# Tests that cannot pass in a deployed/standalone build at all.
SKIP=("test_checkcode")

# Docker Desktop on Windows: from WSL, "docker" may point at a different daemon
# than the one holding the image, so prefer docker.exe when it exists.
DOCKER="$(command -v docker.exe 2>/dev/null || command -v docker)"

echo "SPM container test runner (one container per test file)"
echo "  Docker:  $DOCKER"
echo "  Image:   $IMAGE"
echo "  Log:     $LOG"
echo "  Timeout: ${TIMEOUT_SECS}s per test file"
echo "  Skipped: ${SKIP[*]}"

# -- Locate the SPM tests directory inside the image --------------------------
# The standalone unpacks itself to /opt/spm/spm<VER>_mcr/spm<VER>/ on first run.
TESTS_DIR="$("$DOCKER" run --rm --entrypoint sh "$IMAGE" -c \
    'ls -d /opt/spm/spm*_mcr/spm*/tests 2>/dev/null | head -n 1')"
TESTS_DIR="${TESTS_DIR//$'\r'/}"

if [[ -z "$TESTS_DIR" ]]; then
    echo "ERROR: could not find the tests directory inside $IMAGE." >&2
    echo "       The CTF archive may not have been extracted at build time." >&2
    exit 1
fi
echo "  Tests:   $TESTS_DIR (inside the container)"

# -- Optional: mount the spm-tests-data checkout ------------------------------
MOUNT=()
if [[ -n "${SPM_TESTS_DATA:-}" ]]; then
    if [[ ! -d "$SPM_TESTS_DATA" ]]; then
        echo "ERROR: SPM_TESTS_DATA=$SPM_TESTS_DATA is not a directory." >&2
        exit 1
    fi
    MOUNT=(-v "${SPM_TESTS_DATA}:${TESTS_DIR}/data")
    echo "  Data:    $SPM_TESTS_DATA -> ${TESTS_DIR}/data"
else
    echo "  Data:    not mounted (data-dependent tests will report Incomplete)"
fi
echo ""

# Run as the calling user, so that tests can write to the mounted test data
RUN_AS=(--user "$(id -u):$(id -g)")

# -- Build the test list from the image, not from a source checkout -----------
mapfile -t ALL_TESTS < <(
    "$DOCKER" run --rm --entrypoint sh "$IMAGE" -c \
        "ls ${TESTS_DIR}/test_*.m" 2>/dev/null |
    tr -d '\r' |
    xargs -r -n1 basename |
    sed 's/\.m$//' |
    grep -v '^test_regress_' |
    sort
)

TESTS=()
for t in "${ALL_TESTS[@]}"; do
    skip=false
    for s in "${SKIP[@]}"; do
        [[ "$t" == "$s" ]] && skip=true && break
    done
    [[ "$skip" == false ]] && TESTS+=("$t")
done

# ONLY_TESTS restricts the run to a named subset. Unknown names are an error
# rather than a silent empty run, which would otherwise look like a pass.
if [[ -n "${ONLY_TESTS:-}" ]]; then
    read -r -a WANTED <<< "${ONLY_TESTS//,/ }"
    SUBSET=()
    for w in "${WANTED[@]}"; do
        found=false
        for t in "${TESTS[@]}"; do
            [[ "$t" == "$w" ]] && SUBSET+=("$t") && found=true && break
        done
        if [[ "$found" == false ]]; then
            echo "ERROR: requested test '$w' is not present in $TESTS_DIR." >&2
            exit 1
        fi
    done
    TESTS=("${SUBSET[@]}")
    echo "Restricted to ${#TESTS[@]} test file(s) via ONLY_TESTS"
fi

if [[ ${#TESTS[@]} -eq 0 ]]; then
    echo "ERROR: no test files found in $TESTS_DIR." >&2
    exit 1
fi
echo "Found ${#TESTS[@]} test files"
echo ""

# -- Run ----------------------------------------------------------------------
PASSED=0
FAILED=0
TIMEDOUT=0
FAILED_LIST=()

SKIPPING_UNTIL=false
[[ -n "$START_FROM" ]] && SKIPPING_UNTIL=true

# Print a test's MATLAB output below its status line, folded in a GitHub Actions log
show_output() {
    [[ -n "${GITHUB_ACTIONS:-}" ]] && echo "::group::Output of $TEST_NAME"
    echo "$OUTPUT" | sed 's/^/      | /'
    [[ -n "${GITHUB_ACTIONS:-}" ]] && echo "::endgroup::"
    return 0
}

for TEST_NAME in "${TESTS[@]}"; do
    if [[ "$SKIPPING_UNTIL" == true ]]; then
        if [[ "$TEST_NAME" == "$START_FROM" ]]; then
            SKIPPING_UNTIL=false
        else
            printf "  %-55s skipped\n" "$TEST_NAME"
            continue
        fi
    fi

    # A newline rather than a padded printf: without it the progress line sits
    # unflushed until a result is appended, so in a CI log a hung test looks
    # identical to one that never started.
    echo "  ${TEST_NAME} ..."

    # Verbosity 3 names each test method as it starts, which locates a hang
    EXPR="r=spm_tests('test','${TEST_NAME}','verbose',3); \
p=sum([r.Passed]); f=sum([r.Failed]); inc=sum([r.Incomplete]); \
fprintf('RESULT: passed=%d failed=%d incomplete=%d\n',p,f,inc); \
for j=1:numel(r), if r(j).Failed||r(j).Incomplete, \
fprintf('  FAIL: %s\n',r(j).Name); \
try, \
  rec=r(j).Details.DiagnosticRecord; \
  for k=1:numel(rec), \
    if isprop(rec(k),'Exception') && ~isempty(rec(k).Exception), \
      fprintf('  ERROR_ID: %s\n',rec(k).Exception.identifier); \
      fprintf('  ERROR_MSG: %s\n',rec(k).Exception.message); \
    elseif isprop(rec(k),'Report') && ~isempty(rec(k).Report), \
      fprintf('  REPORT: %s\n',rec(k).Report); \
    end; \
  end; \
catch err, fprintf('  (no diagnostic: %s)\n',err.message); end; \
end; end; exit(0);"

    # Run detached and poll, rather than "timeout docker run".
    #
    # With an attached CLI, timeout sends SIGTERM to the docker client, which
    # forwards it to the container and then waits. A MATLAB Runtime process
    # blocked on a graphics call ignores SIGTERM, so the client never exits,
    # timeout never escalates (there is no second signal without --kill-after),
    # and the surrounding $( ) blocks forever because the pipe stays open. The
    # runner would then hang on precisely the tests it exists to catch.
    #
    # Detached, nothing is attached to the container's lifetime: the deadline is
    # enforced here and "rm -f" is an immediate SIGKILL with no grace period.
    CONTAINER="spm_test_${TEST_NAME}_$$"
    "$DOCKER" rm -f "$CONTAINER" >/dev/null 2>&1 || true

    if ! "$DOCKER" run -d --name "$CONTAINER" "${RUN_AS[@]}" "${MOUNT[@]}" "$IMAGE" \
            eval "$EXPR" >/dev/null 2>&1; then
        echo "      ERROR (could not start container)"
        FAILED=$((FAILED + 1))
        FAILED_LIST+=("$TEST_NAME  [START FAILED]")
        "$DOCKER" rm -f "$CONTAINER" >/dev/null 2>&1 || true
        continue
    fi

    ELAPSED=0
    TIMED_OUT=false
    while true; do
        STATE=$("$DOCKER" inspect -f '{{.State.Running}}' "$CONTAINER" 2>/dev/null || echo false)
        [[ "$STATE" != "true" ]] && break
        if (( ELAPSED >= TIMEOUT_SECS )); then
            TIMED_OUT=true
            break
        fi
        sleep 2
        ELAPSED=$((ELAPSED + 2))
    done

    OUTPUT=$("$DOCKER" logs "$CONTAINER" 2>&1)
    PROCESSES=""
    [[ "$TIMED_OUT" == true ]] && PROCESSES=$("$DOCKER" top "$CONTAINER" 2>&1)
    "$DOCKER" rm -f "$CONTAINER" >/dev/null 2>&1 || true

    PASSING=false
    if [[ "$TIMED_OUT" == true ]]; then
        # Almost always a blocked graphics call: figure(), uiwait(), spm_input()
        echo "      TIMEOUT (likely a graphics/GUI call)"
        TIMEDOUT=$((TIMEDOUT + 1))
        FAILED_LIST+=("$TEST_NAME  [TIMEOUT]")
        OUTPUT=$(printf '%s\nEXCEPTION: timed out after %ss\nProcesses in the container at the timeout:\n%s' \
            "$OUTPUT" "$TIMEOUT_SECS" "$PROCESSES")
    else
        RESULT_LINE=$(echo "$OUTPUT" | grep '^RESULT:')
        FAIL_COUNT=$(echo "$RESULT_LINE" | sed -n 's/.* failed=\([0-9]*\).*/\1/p')
        INC_COUNT=$(echo  "$RESULT_LINE" | sed -n 's/.* incomplete=\([0-9]*\).*/\1/p')

        if [[ -z "$RESULT_LINE" ]]; then
            echo "      CRASHED (no result line)"
            FAILED=$((FAILED + 1))
            FAILED_LIST+=("$TEST_NAME  [CRASHED]")
        elif [[ "${FAIL_COUNT:-0}" -gt 0 ]]; then
            echo "      FAILED"
            FAILED=$((FAILED + 1))
            FAILED_LIST+=("$TEST_NAME  [${FAIL_COUNT} failed, ${INC_COUNT:-0} incomplete]")
        elif [[ "${INC_COUNT:-0}" -gt 0 ]]; then
            echo "      ok (${INC_COUNT} incomplete)"
            PASSED=$((PASSED + 1))
            PASSING=true
        else
            echo "      ok"
            PASSED=$((PASSED + 1))
            PASSING=true
        fi
    fi

    # The output of a passing test is only shown where the log can fold it
    [[ "$PASSING" == true && -z "${GITHUB_ACTIONS:-}" ]] || show_output

    {
        echo "===TEST_FILE: $TEST_NAME==="
        echo "$OUTPUT"
        echo ""
    } >> "$LOG"
done

# -- Summary ------------------------------------------------------------------
echo ""
echo "================================================================"
echo "SUMMARY"
echo "================================================================"
echo "  Passed:   $PASSED"
echo "  Failed:   $FAILED"
echo "  Timeouts: $TIMEDOUT"
echo "  Skipped:  ${#SKIP[@]}"
echo ""

if [[ ${#FAILED_LIST[@]} -gt 0 ]]; then
    echo "Not passing:"
    for t in "${FAILED_LIST[@]}"; do
        echo "  $t"
    done
    echo ""
fi

echo "Full output: $LOG"

# -- Optional Markdown summary ------------------------------------------------
if [[ -n "${SUMMARY_FILE:-}" ]]; then
    {
        echo "### SPM container unit tests"
        echo ""
        echo "Image \`${IMAGE}\`, ${TIMEOUT_SECS}s timeout per test file."
        echo ""
        echo "| Passed | Failed | Timed out | Skipped |"
        echo "|---:|---:|---:|---:|"
        echo "| $PASSED | $FAILED | $TIMEDOUT | ${#SKIP[@]} |"
        if [[ ${#FAILED_LIST[@]} -gt 0 ]]; then
            echo ""
            echo "#### Not passing"
            echo ""
            for t in "${FAILED_LIST[@]}"; do
                echo "- \`${t%% *}\` ${t#* }"
            done
            echo ""
            echo "A \`TIMEOUT\` almost always means the test reached for graphics"
            echo "(\`figure\`, \`uiwait\`, \`spm_input\`), which blocks in a headless container."
        fi
    } > "$SUMMARY_FILE"
fi

[[ ${#FAILED_LIST[@]} -eq 0 ]]
