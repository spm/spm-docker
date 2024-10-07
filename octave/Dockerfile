FROM gnuoctave/octave:9.2.0

ENV SPM_VERSION=24.10
ENV SPM_REVISION=alpha8
ENV SPM_NAME=${SPM_VERSION}${SPM_REVISION:+.${SPM_REVISION}}

LABEL org.opencontainers.image.authors="SPM <fil.spm@ucl.ac.uk>"
LABEL org.opencontainers.image.source="https://github.com/spm/spm-docker"
LABEL org.opencontainers.image.url="https://www.fil.ion.ucl.ac.uk/spm/"
LABEL org.opencontainers.image.documentation="https://www.fil.ion.ucl.ac.uk/spm/docs/"
LABEL org.opencontainers.image.version="${SPM_VERSION}"
LABEL org.opencontainers.image.revision="${SPM_REVISION}"
LABEL org.opencontainers.image.vendor="Functional Imaging Laboratory"
LABEL org.opencontainers.image.licenses="GPL-2.0+"
LABEL org.opencontainers.image.title="Statistical Parametric Software"
LABEL org.opencontainers.image.description="Analysis of brain imaging data sequences (fMRI, PET, EEG, MEG)"

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -y install \
        build-essential curl unzip \
    && apt-get clean \
    && rm -rf \
        /tmp/hsperfdata* \
        /var/*/apt/*/partial \
        /var/lib/apt/lists/* \
        /var/log/apt/term*

RUN mkdir /opt/spm \
    && curl -SL "https://github.com/spm/spm/archive/refs/heads/main.tar.gz" \
    | tar -xzC /opt/spm --strip-components 1

    # RUN curl -SL https://raw.githubusercontent.com/spm/spm-octave/main/spm12_r7771.patch \
    #  | patch -p0 
    RUN make -C /opt/spm/src PLATFORM=octave distclean 
     RUN make -C /opt/spm/src PLATFORM=octave 
     RUN make -C /opt/spm/src PLATFORM=octave install 
     RUN ln -s /opt/spm/bin/spm-octave /usr/local/bin/spm

RUN octave --no-gui --eval "addpath (\"/opt/spm\"); savepath ();"

 ENTRYPOINT ["spm"]

 CMD ["--help"]
