FROM ubuntu:22.04

LABEL org.opencontainers.image.authors="SPM <fil.spm@ucl.ac.uk>"
LABEL org.opencontainers.image.source="https://github.com/spm/spm-docker"
LABEL org.opencontainers.image.url="https://www.fil.ion.ucl.ac.uk/spm/"
LABEL org.opencontainers.image.documentation="https://www.fil.ion.ucl.ac.uk/spm/docs/"
LABEL org.opencontainers.image.version="SPM12"
LABEL org.opencontainers.image.revision="dev"
LABEL org.opencontainers.image.vendor="Functional Imaging Laboratory"
LABEL org.opencontainers.image.licenses="GPL-2.0+"
LABEL org.opencontainers.image.title="Statistical Parametric Software"
LABEL org.opencontainers.image.description="Analysis of brain imaging data sequences (fMRI, PET, EEG, MEG)"

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -y install \
     build-essential \
     curl \
     octave \
     liboctave-dev \
 && apt-get clean \
 && rm -rf \
     /tmp/hsperfdata* \
     /var/*/apt/*/partial \
     /var/lib/apt/lists/* \
     /var/log/apt/term*

RUN mkdir /opt/spm12 \
 && curl -SL https://github.com/spm/spm12/archive/r7771.tar.gz \
  | tar -xzC /opt/spm12 --strip-components 1 \
 && curl -SL https://raw.githubusercontent.com/spm/spm-octave/main/spm12_r7771.patch \
  | patch -p0 \
 && make -C /opt/spm12/src PLATFORM=octave distclean \
 && make -C /opt/spm12/src PLATFORM=octave \
 && make -C /opt/spm12/src PLATFORM=octave install \
 && ln -s /opt/spm12/bin/spm12-octave /usr/local/bin/spm12

#RUN octave --no-gui --eval "addpath (\"/opt/spm12\"); savepath ();"

ENTRYPOINT ["spm12"]

CMD ["--help"]
