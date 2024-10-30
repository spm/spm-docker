FROM ubuntu:latest

ARG MATLAB_VERSION=R2024b
ARG AGREE_TO_MATLAB_RUNTIME_LICENSE=yes
ARG SPM_VERSION=24
ARG SPM_RELEASE=24.10
ARG SPM_REVISION=alpha22
# Calculated
ENV SPM_TAG=${SPM_RELEASE}${SPM_REVISION:+.${SPM_REVISION}}

LABEL org.opencontainers.image.authors="SPM <fil.spm@ucl.ac.uk>"
LABEL org.opencontainers.image.source="https://github.com/spm/spm-docker"
LABEL org.opencontainers.image.url="https://www.fil.ion.ucl.ac.uk/spm/"
LABEL org.opencontainers.image.documentation="https://www.fil.ion.ucl.ac.uk/spm/docs/"
LABEL org.opencontainers.image.version="${SPM_RELEASE}"
LABEL org.opencontainers.image.revision="${SPM_REVISION}"
LABEL org.opencontainers.image.vendor="Functional Imaging Laboratory"
LABEL org.opencontainers.image.licenses="GPL-2.0+"
LABEL org.opencontainers.image.title="Statistical Parametric Mapping (SPM) Software"
LABEL org.opencontainers.image.description="SPM Software and selected third-party extensions"

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -y install \
    unzip xorg wget \
    && apt-get clean \
    && rm -rf \
    /tmp/hsperfdata* \
    /var/*/apt/*/partial \
    /var/lib/apt/lists/* \
    /var/log/apt/term*

ENV LD_LIBRARY_PATH=/usr/local/MATLAB/MATLAB_Runtime/${MATLAB_VERSION}/runtime/glnxa64:/usr/local/MATLAB/MATLAB_Runtime/${MATLAB_VERSION}/bin/glnxa64:/usr/local/MATLAB/MATLAB_Runtime/${MATLAB_VERSION}/sys/os/glnxa64:/usr/local/MATLAB/MATLAB_Runtime/${MATLAB_VERSION}/sys/opengl/lib/glnxa64:/usr/local/MATLAB/MATLAB_Runtime/${MATLAB_VERSION}/extern/bin/glnxa64
ENV MCR_INHIBIT_CTF_LOCK=1
ENV SPM_HTML_BROWSER=0

# Install SPM Standalone in /opt/spm/
# Running SPM once with "function exit" tests the succesfull installation *and*
# extracts the ctf archive which is necessary if singularity is going to be
# used later on, because singularity containers are read-only.
# Also, set +x on the entrypoint for non-root container invocations
RUN wget --no-check-certificate --progress=bar:force -P /opt https://github.com/spm/spm/releases/download/${SPM_TAG}/spm_standalone_${SPM_TAG}_Linux.zip \
    && unzip -q /opt/spm_standalone_${SPM_TAG}_Linux.zip -d /opt \
    && rm -f /opt/spm_standalone_${SPM_TAG}_Linux.zip \
    && mv /opt/spm_standalone /opt/spm \
    && /opt/runtime_installer/Runtime_${MATLAB_VERSION}_for_spm_standalone_${SPM_TAG}.install -agreeToLicense ${AGREE_TO_MATLAB_RUNTIME_LICENSE} \
    && /opt/spm/spm${SPM_VERSION} function exit \
    && chmod +x /opt/spm/spm${SPM_VERSION} \
    && ln -s /opt/spm/spm${SPM_VERSION} /usr/local/bin/spm

# Configure entry point
ENTRYPOINT ["spm"]
CMD ["--help"]
