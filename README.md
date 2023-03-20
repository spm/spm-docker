# SPM Containers

## Technology

### Docker

Docker is a container technology, performing operating-system-level
virtualisation.

* [Docker](https://www.docker.com/)

### Singularity

Singularity is another container technology that performs
operating-system-level virtualization. One of the main uses of
Singularity is to bring containers and reproducibility to scientific
computing and HPC.

* [SingularityCE](https://sylabs.io/singularity/)  
* [Apptainer](https://apptainer.org/)

## SPM Containers

Official SPM `Dockerfile` and `singularity.def` (using the Standalone SPM or Octave):

### [Dockerfile](https://docs.docker.com/engine/reference/builder/) for [SPM](https://www.fil.ion.ucl.ac.uk/software/spm12/)

* [Dockerfile](https://github.com/spm/spm-docker/blob/main/matlab/Dockerfile) using [SPM Standalone](https://www.wikibooks.org/wiki/SPM/Standalone) and [MATLAB Runtime](https://www.mathworks.com/products/compiler/matlab-runtime.html)
* [Dockerfile](https://github.com/spm/spm-docker/blob/main/octave/Dockerfile) using [GNU Octave](https://www.octave.org/)

### [Singularity Definition File](https://sylabs.io/guides/3.5/user-guide/definition_files.html) for [SPM](https://www.fil.ion.ucl.ac.uk/software/spm12/)

* [singularity.def](https://github.com/spm/spm-docker/blob/main/matlab/singularity.def) using [SPM Standalone](https://www.wikibooks.org/wiki/SPM/Standalone) and [MATLAB Runtime](https://www.mathworks.com/products/compiler/matlab-runtime.html)
* [singularity.def](https://github.com/spm/spm-docker/blob/main/octave/singularity.def) using [GNU Octave](https://www.octave.org/)

## Container Registry

Pre-built images are available from [GitHub Packages](https://github.com/spm/spm-docker/pkgs/container/spm-docker):

* [GitHub Packages Container registry](https://ghcr.io/)

```
docker pull ghcr.io/spm/spm-docker:docker-matlab
docker pull ghcr.io/spm/spm-docker:docker-octave
```

```
singularity pull oras://ghcr.io/spm/spm-docker:matlab
singularity pull oras://ghcr.io/spm/spm-docker:octave
```

See also a [Docker image](https://github.com/spm/spm-docker/blob/main/tbx/Dockerfile) for SPM Standalone and selected [third-party toolboxes](https://github.com/spm-toolboxes/) with the MATLAB Runtime:

```
docker pull ghcr.io/spm/spm-docker:docker-tbx
```

## Usage

For example, to start SPM with its graphical user interface, use the following:

```
xhost +local:docker  
docker run -ti --rm -e DISPLAY=$DISPLAY -v /tmp:/tmp -v /tmp/.X11-unix:/tmp/.X11-unix ghcr.io/spm/spm-docker:docker-matlab fmri
```

If the container\'s root filesystem is mounted as read only
(`--read-only` flag), you need to bind mount an extra volume:

```
-v /tmp/.matlab:/root/.matlab
```

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

```
sudo singularity build spm12.sif spm12-octave.def
singularity exec spm12.sif
./spm12.sif --help
```

([how to install singularity on
Ubuntu](https://github.com/hpcng/singularity/issues/5390#issuecomment-899111181))

### [Docker Hub](https://hub.docker.com/r/spmcentral/spm/) (deprecated)

SPM Docker images used to be hosted on Docker Hub but this is now deprecated and the GitHub Packages Container Registry should be used instead.

```
docker pull spmcentral/spm:latest
docker pull spmcentral/spm:octave
```