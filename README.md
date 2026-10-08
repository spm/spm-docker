# SPM Containers

This repository provides github action workflows for automatic docker and singularity image creation. They are triggered by releasing a new SPM version.

## Containers

The containers are hosted on the [**GitHub Container Registry**](https://github.com/spm/spm-docker/pkgs/container/spm-docker)

```bash
docker pull ghcr.io/spm/spm-docker:docker-matlab-latest
docker pull ghcr.io/spm/spm-docker:docker-octave-latest
```

```bash
singularity pull oras://ghcr.io/spm/spm-docker:singularity-matlab-latest
singularity pull oras://ghcr.io/spm/spm-docker:singularity-octave-latest
```

## Usage

For example, to start SPM with its graphical user interface, use the following:

```bash
xhost +local:docker  
docker run -ti --rm -e DISPLAY=$DISPLAY -v /tmp:/tmp -v /tmp/.X11-unix:/tmp/.X11-unix ghcr.io/spm/spm-docker:docker-matlab-latest fmri
```

If the container\'s root filesystem is mounted as read only
(`--read-only` flag), you need to bind mount an extra volume:

```bash
-v /tmp/.matlab:/home/spm/.matlab
```

The folder on the host has to exist and be writable by the container user.

### User inside the container

The MATLAB container runs as an ordinary user (`spm`, uid 1000), not as root.
To let SPM write its results to a mounted folder, run it as yourself:

```bash
docker run --rm --user $(id -u):$(id -g) -v /path/to/data:/data \
  ghcr.io/spm/spm-docker:docker-matlab-latest batch /data/job.m
```

`--user root` is still possible, but figures do not work for root: without a
display, the MATLAB Runtime draws the first figure and hangs on the next one.

An image built `FROM` this one inherits the user. Switch to `USER root` for
steps that install software, and back to `USER spm` afterwards.

## Testing

The containers run SPM Standalone headless, with no X server. The whole unit
test suite can be run in one shot:

```bash
docker run --rm ghcr.io/spm/spm-docker:docker-matlab-latest test
```

Some tests need the data from the private `spm/spm-tests-data` repository.
Without it they report as *Incomplete*, which is not a failure. To supply it,
bind mount a checkout over the `tests/data` directory inside the container
(`NN` is the SPM major version, e.g. `26`). The tests write to that folder, so
run the container as its owner:

```bash
docker run --rm --user $(id -u):$(id -g) \
  -v /path/to/spm-tests-data:/opt/spm/spmNN_mcr/spmNN/tests/data \
  ghcr.io/spm/spm-docker:docker-matlab-latest test
```

To find a failing or hanging test, `matlab/run_tests.sh` runs each test file in
its own container with a timeout. It prints the MATLAB output of every test
that does not pass, and in a GitHub Actions log of every test, one folded
section per test file.

### Why the octave image only gets a smoke test

`spm_tests` is built on `matlab.unittest`, which GNU Octave does not provide,
and it has no Octave code path. Separately, the `bin/spm-octave` launcher ends
with a `waitfor` loop over open figures, so a test that leaves a figure behind
would hang the container indefinitely. Running the suite under Octave needs both
of those addressed in the SPM repository first.

## Technology

### Docker

[Docker](https://www.docker.com/) is a container technology, performing operating-system-level
virtualisation.

### Singularity

Singularity is another container technology that performs operating-system-level virtualization. One of the main uses of Singularity is to bring containers and reproducibility to scientific computing and HPC.

* [SingularityCE](https://sylabs.io/singularity/)
* [Apptainer](https://apptainer.org/)

## SPM Containers Creation

The official SPM `Dockerfiles`:

* [Dockerfile](https://github.com/spm/spm-docker/blob/main/matlab/Dockerfile) using the [SPM Standalone](https://www.fil.ion.ucl.ac.uk/spm/docs/installation/standalone/)
* [Dockerfile](https://github.com/spm/spm-docker/blob/main/octave/Dockerfile) using [GNU Octave](https://www.octave.org/)
* [Dockerfile.local](https://github.com/spm/spm-docker/blob/main/matlab/Dockerfile.local) wrapping a locally built standalone, used to test unreleased SPM

The singularity `sif` images are created from the docker images.

## Documentation

Check the [SPM online documentation](https://www.fil.ion.ucl.ac.uk/spm/docs/installation/containers/).

## See also

### Neurodesk

[https://www.neurodesk.org/](https://www.neurodesk.org/)

### Neurodocker

[https://github.com/ReproNim/neurodocker](https://github.com/ReproNim/neurodocker)  
[https://hub.docker.com/r/kaczmarj/neurodocker/](https://hub.docker.com/r/kaczmarj/neurodocker/)

### SPM BIDS-App

https://github.com/BIDS-Apps/SPM`](https://github.com/BIDS-Apps/SPM)  
[https://hub.docker.com/r/bids/spm/](https://hub.docker.com/r/bids/spm/)

### MATLAB Dockerfile

[https://github.com/mathworks-ref-arch/matlab-dockerfile](https://github.com/mathworks-ref-arch/matlab-dockerfile)

### Singularity

[SingularityCE User Guide](https://sylabs.io/guides/3.8/user-guide/)

```bash
sudo singularity build spm12.sif spm12-octave.def
singularity exec spm12.sif
./spm12.sif --help
```

([how to install singularity on
Ubuntu](https://github.com/hpcng/singularity/issues/5390#issuecomment-899111181))

### [Docker Hub](https://hub.docker.com/r/spmcentral/spm/) (deprecated)

SPM Docker images used to be hosted on Docker Hub but this is now deprecated and the GitHub Packages Container Registry should be used instead.

```bash
docker pull spmcentral/spm:latest
docker pull spmcentral/spm:octave
```
