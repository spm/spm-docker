#!/usr/bin/env bash
# Start the container build for the newest SPM release, unless its images
# exist or a build for it was started before.
# DRY_RUN=1 prints the decision and starts nothing.
set -euo pipefail

SPM_REPO=spm/spm
REPO=${GITHUB_REPOSITORY:-spm/spm-docker}

# Version tags only (26.10, 26.10.01, 26.10.rc1). Development builds
# (dev-<sha>) are not built as containers.
tag=$(gh api "repos/$SPM_REPO/releases?per_page=30" --jq '
  [.[] | select(.draft | not)
       | select(.tag_name | test("^[0-9]{2}[.][0-9]{2}([.][0-9A-Za-z]+)?$"))]
  | sort_by(.published_at) | last | .tag_name // empty')
if [ -z "$tag" ]; then
  echo "No SPM release found."
  exit 0
fi
echo "Newest SPM release: $tag"

# The Octave image is built from the source zip, the MATLAB image from the
# Linux standalone. Wait until the release workflow has uploaded both.
assets=$(gh api "repos/$SPM_REPO/releases/tags/$tag" \
  --jq '.assets[] | select(.state == "uploaded") | .name')
for asset in "spm_$tag.zip" "spm_standalone_${tag}_Linux.zip"; do
  if ! grep -qxF "$asset" <<< "$assets"; then
    echo "$asset is not uploaded yet. Nothing to do."
    exit 0
  fi
done

# Ask the registry for each image tag: 200 means it exists, 404 that it is
# missing. Anything else is an error and must not be taken for a missing image.
token=$(curl -fsSL "https://ghcr.io/token?scope=repository:$REPO:pull" |
  sed 's/.*"token":"\([^"]*\)".*/\1/')
accept="Accept: application/vnd.oci.image.index.v1+json, application/vnd.oci.image.manifest.v1+json, application/vnd.docker.distribution.manifest.list.v2+json, application/vnd.docker.distribution.manifest.v2+json"
missing=""
for recipe in matlab octave; do
  image="docker-$recipe-$tag"
  status=$(curl -sS -o /dev/null -w '%{http_code}' \
    -H "Authorization: Bearer $token" -H "$accept" \
    "https://ghcr.io/v2/$REPO/manifests/$image")
  case "$status" in
    200) ;;
    404) missing="$missing $image" ;;
    *)
      echo "::error::The registry answered $status for $image."
      exit 1
      ;;
  esac
done
if [ -z "$missing" ]; then
  echo "The images of $tag exist. Nothing to do."
  exit 0
fi
echo "Missing:$missing"

# One automatic build per release. The title is set by run-name in
# build-docker.yml, so a build started by hand counts as well.
title="Build SPM $tag"
run=$(gh run list --repo "$REPO" --workflow build-docker.yml --limit 100 \
  --json displayTitle,status,url --jq '.[] | [.displayTitle, .status, .url] | @tsv' |
  awk -F'\t' -v title="$title" '$1 == title && !found { print $2, $3; found = 1 }')
if [ -n "$run" ]; then
  if [ "${run%% *}" = completed ]; then
    echo "::error::The build of SPM $tag finished without publishing its images: ${run#* }. Start it again by hand once the cause is fixed."
    exit 1
  fi
  echo "The build of SPM $tag is running: ${run#* }"
  exit 0
fi

# The MATLAB image installs the Runtime that is bundled with the standalone,
# and its file name carries the MATLAB release.
tmp=$(mktemp -d)
curl -fsSL -o "$tmp/standalone.zip" \
  "https://github.com/$SPM_REPO/releases/download/$tag/spm_standalone_${tag}_Linux.zip"
matlab=$(unzip -Z1 "$tmp/standalone.zip" |
  sed -n 's|^runtime_installer/Runtime_\(R20[0-9][0-9][ab]\)_for_spm_standalone_.*|\1|p' |
  sort -u)
rm -rf "$tmp"
if [ -z "$matlab" ]; then
  echo "::error::No Runtime installer found in the Linux standalone of $tag."
  exit 1
fi

echo "Starting the build of SPM $tag (MATLAB $matlab)"
if [ -n "${DRY_RUN:-}" ]; then
  exit 0
fi
gh workflow run build-docker.yml --repo "$REPO" \
  -f spm_release="${tag:0:5}" -f spm_revision="${tag:6}" -f matlab_version="$matlab"
