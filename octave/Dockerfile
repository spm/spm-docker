FROM gnuoctave/octave:latest

ARG SPM_VERSION=24
ARG SPM_RELEASE=24.10
ARG SPM_REVISION=alpha16
# Calculated
ENV SPM_TAG=${SPM_RELEASE}${SPM_REVISION:+.${SPM_REVISION}}

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
        build-essential unzip \
    && apt-get clean \
    && rm -rf \
        /tmp/hsperfdata* \
        /var/*/apt/*/partial \
        /var/lib/apt/lists/* \
        /var/log/apt/term*

RUN wget --no-check-certificate --progress=bar:force -P /opt https://github.com/spm/spm/releases/download/${SPM_TAG}/spm_${SPM_TAG}.zip \
    && unzip -q /opt/spm_${SPM_TAG}.zip -d /opt \
    && rm -f /opt/spm_${SPM_TAG}.zip
    RUN make -C /opt/spm/src PLATFORM=octave distclean 
    RUN make -C /opt/spm/src PLATFORM=octave 
    RUN make -C /opt/spm/src PLATFORM=octave install 
    RUN ln -s "/opt/spm/bin/spm-octave /usr/local/bin/spm${SPM_VERSION}"

    # TODO octave patch required?
    # RUN curl -SL https://raw.githubusercontent.com/spm/spm-octave/main/spm12_r7771.patch \
    #  | patch -p0 

RUN octave --no-gui --eval "addpath ('/opt/spm${SPM_VERSION}'); savepath ();"

ENTRYPOINT ["spm${SPM_VERSION}"]

CMD ["--help"]
