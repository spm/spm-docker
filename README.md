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
-v /tmp/.matlab:/root/.matlab
```

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
* [Dockerfile](https://github.com/spm/spm-docker/blob/main/matlab/Dockerfile) using the [SPM Standalone](https://www.fil.ion.ucl.ac.uk/spm/docs/installation/standalone/) and selected [third-party toolboxes](https://github.com/spm-toolboxes/) (outdated)

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
