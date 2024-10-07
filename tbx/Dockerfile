FROM ubuntu:20.04

ENV MATLAB_VERSION=R2024b
ENV MCR_UPDATE=6

ENV SPM_REVISION=24.10-alpha8


LABEL org.opencontainers.image.authors="SPM <fil.spm@ucl.ac.uk>"
LABEL org.opencontainers.image.source="https://github.com/spm/spm-docker"
LABEL org.opencontainers.image.url="https://www.fil.ion.ucl.ac.uk/spm/"
LABEL org.opencontainers.image.documentation="https://www.fil.ion.ucl.ac.uk/spm/docs/"
LABEL org.opencontainers.image.version="SPM"
LABEL org.opencontainers.image.revision="dev"
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

# Install MATLAB MCR in /opt/mcr/
RUN mkdir /opt/mcr_install \
 && mkdir /opt/mcr \
 && wget --progress=bar:force -P /opt/mcr_install https://ssd.mathworks.com/supportfiles/downloads/${MATLAB_VERSION}/Release/${MCR_UPDATE}/deployment_files/installer/complete/glnxa64/MATLAB_Runtime_${MATLAB_VERSION}_Update_${MCR_UPDATE}_glnxa64.zip \
 && unzip -q /opt/mcr_install/MATLAB_Runtime_${MATLAB_VERSION}_Update_${MCR_UPDATE}_glnxa64.zip -d /opt/mcr_install \
 && /opt/mcr_install/install -destinationFolder /opt/mcr -agreeToLicense yes -mode silent \
 && rm -rf /opt/mcr_install /tmp/*
ENV LD_LIBRARY_PATH=/opt/mcr/${MATLAB_VERSION}/runtime/glnxa64:/opt/mcr/${MATLAB_VERSION}/bin/glnxa64:/opt/mcr/${MATLAB_VERSION}/sys/os/glnxa64:/opt/mcr/${MATLAB_VERSION}/sys/opengl/lib/glnxa64:/opt/mcr/${MATLAB_VERSION}/extern/bin/glnxa64
ENV MCR_INHIBIT_CTF_LOCK=1
ENV SPM_HTML_BROWSER=0

# Install SPM Standalone in /opt/spm/
RUN echo $TBX
# Running SPM once with "function exit" tests the succesfull installation *and*
# extracts the ctf archive which is necessary if singularity is going to be
# used later on, because singularity containers are read-only.
# Also, set +x on the entrypoint for non-root container invocations
ENV SPM_REVISION=24.10-alpha8
RUN wget --no-check-certificate --progress=bar:force -P /opt https://github.com/korbinian90/spm_actions/releases/download/${SPM_REVISION}/spm_${SPM_REVISION}_Linux_${MATLAB_VERSION}.zip \
 && unzip -q /opt/spm_${SPM_REVISION}_Linux_${MATLAB_VERSION}.zip -d /opt \
 && mv /opt/spm_${SPM_REVISION}_Linux_${MATLAB_VERSION} /opt/spm \
 && rm -f /opt/spm_${SPM_REVISION}_Linux_${MATLAB_VERSION}.zip
 
RUN /opt/spm/run_spm12.sh /opt/mcr/${MATLAB_VERSION} function exit \
 && chmod +x /opt/spm/spm12

# Configure entry point
ENTRYPOINT ["/opt/spm/spm12"]
CMD ["--help"]
