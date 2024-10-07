FROM containers.mathworks.com/matlab-runtime:r2024b

ENV MATLAB_VERSION=R2024b
ENV AGREE_TO_MATLAB_RUNTIME_LICENSE=yes
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

ENV LD_LIBRARY_PATH=/opt/matlabruntime/${MATLAB_VERSION}/runtime/glnxa64:/opt/matlabruntime/${MATLAB_VERSION}/bin/glnxa64:/opt/matlabruntime/${MATLAB_VERSION}/sys/os/glnxa64:/opt/matlabruntime/${MATLAB_VERSION}/sys/opengl/lib/glnxa64:/opt/matlabruntime/${MATLAB_VERSION}/extern/bin/glnxa64
ENV MCR_INHIBIT_CTF_LOCK=1
ENV SPM_HTML_BROWSER=0

# Install SPM Standalone in /opt/spm/
# Running SPM once with "function exit" tests the succesfull installation *and*
# extracts the ctf archive which is necessary if singularity is going to be
# used later on, because singularity containers are read-only.
# Also, set +x on the entrypoint for non-root container invocations
RUN wget --no-check-certificate --progress=bar:force -P /opt https://github.com/korbinian90/spm_actions/releases/download/${SPM_NAME}/spm_standalone_${SPM_NAME}_Linux_${MATLAB_VERSION}.zip \
    && unzip -q /opt/spm_standalone_${SPM_NAME}_Linux_${MATLAB_VERSION}.zip -d /opt \
    && mv /opt/spm_standalone_${SPM_NAME}_Linux_${MATLAB_VERSION} /opt/spm \
    && rm -f /opt/spm_standalone_${SPM_NAME}_Linux_${MATLAB_VERSION}.zip \
    && /opt/spm/spm12 function exit \
    && chmod +x /opt/spm/spm12

# Configure entry point
ENTRYPOINT ["/opt/spm/spm12"]
CMD ["--help"]
