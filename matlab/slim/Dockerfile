FROM ubuntu:bionic

MAINTAINER Guillaume Flandin <g.flandin@ucl.ac.uk>

RUN apt-get update \
 && apt-get -y install unzip libxt6 wget \
 && apt-get clean \
 && rm -rf \
     /tmp/hsperfdata* \
     /var/*/apt/*/partial \
     /var/lib/apt/lists/* \
     /var/log/apt/term*

# Install MATLAB MCR in /opt/mcr/
# To save space we are removing all archives except Core and Numerics, and
# we're kiling some of the larger blobs in the mcr as wel: Qt5 and cuda-related
# libraries and map tiles. This list could be amended over time.
ENV MATLAB_VERSION R2018b
ENV MCR_VERSION v95
RUN mkdir /opt/mcr_install \
 && mkdir /opt/mcr \
 && wget -P /opt/mcr_install --progress=bar:force https://www.mathworks.com/supportfiles/downloads/${MATLAB_VERSION}/deployment_files/${MATLAB_VERSION}/installers/glnxa64/MCR_${MATLAB_VERSION}_glnxa64_installer.zip \
 && unzip -q /opt/mcr_install/MCR_${MATLAB_VERSION}_glnxa64_installer.zip -d /opt/mcr_install \
 && rm /opt/mcr_install/archives/*GPU* \
 && rm /opt/mcr_install/archives/*Hadoop* \
 && rm /opt/mcr_install/archives/*Java* \
 && rm /opt/mcr_install/archives/*MPS* \
 && rm /opt/mcr_install/archives/*NET* \
 && rm /opt/mcr_install/archives/*Web_Apps* \
 && /opt/mcr_install/install -destinationFolder /opt/mcr -agreeToLicense yes -mode silent \
 && rm -rf /opt/mcr_install /tmp/* \
 && rm -rf /opt/mcr/${MCR_VERSION}/etc \
 && rm -rf /opt/mcr/${MCR_VERSION}/bin/glnxa64/libQt5* \
 && rm -rf /opt/mcr/${MCR_VERSION}/bin/glnxa64/qtwebengine* \
 && rm -rf /opt/mcr/${MCR_VERSION}/mcr/toolbox/matlab/maps \
 && rm -rf /opt/mcr/${MCR_VERSION}/resources/*/ja_JP \
 && rm -rf /opt/mcr/${MCR_VERSION}/resources/*/ko_KR \
 && rm -rf /opt/mcr/${MCR_VERSION}/resources/*/zh_CN \
 && rm -rf /opt/mcr/${MCR_VERSION}/cefclient \
 && rm -rf /opt/mcr/${MCR_VERSION}/bin/glnxa64/cef_* \
 && rm -rf /opt/mcr/${MCR_VERSION}/sys/opengl \
 && rm -rf /opt/mcr/${MCR_VERSION}/sys/jxbrowser \
 && rm -rf /opt/mcr/${MCR_VERSION}/java/jarext/jxbrowser* \
 && rm -rf /opt/mcr/${MCR_VERSION}/sys/tex \
 && rm -rf /opt/mcr/${MCR_VERSION}/sys/java/jre/glnxa64/jre/lib/amd64/libjfxwebkit.so \
 && rm -rf /opt/mcr/${MCR_VERSION}/toolbox/matlab/datools \
 && rm -rf /opt/mcr/${MCR_VERSION}/toolbox/matlab/codetools \
 && rm -rf /opt/mcr/${MCR_VERSION}/toolbox/matlab/uitools \
 && rm -rf /opt/mcr/${MCR_VERSION}/toolbox/matlab/system \
 && rm -rf /opt/mcr/${MCR_VERSION}/toolbox/matlab/codeanalysis \
 && rm -rf /opt/mcr/${MCR_VERSION}/toolbox/matlab/pathdataservice \
 && rm -rf /opt/mcr/${MCR_VERSION}/toolbox/coder \
 && rm -rf /opt/mcr/${MCR_VERSION}/toolbox/glee \
 && rm -rf /opt/mcr/${MCR_VERSION}/toolbox/simulink \
 && rm -rf /opt/mcr/${MCR_VERSION}/toolbox/shared/dastudio \
 && rm -rf /opt/mcr/${MCR_VERSION}/toolbox/shared/mlreportgen

# Install SPM Standalone in /opt/spm12/
ENV SPM_VERSION 12
ENV SPM_REVISION r7487
ENV LD_LIBRARY_PATH /opt/mcr/${MCR_VERSION}/runtime/glnxa64:/opt/mcr/${MCR_VERSION}/bin/glnxa64:/opt/mcr/${MCR_VERSION}/sys/os/glnxa64:/opt/mcr/${MCR_VERSION}/sys/opengl/lib/glnxa64
ENV MCR_INHIBIT_CTF_LOCK 1
ENV SPM_HTML_BROWSER 0
# Running spm once with "function exit" tests the succesfull installation *and*
# extracts the ctf archive which is necessary if singularity is going to be
# used later on, because singularity containers are read-only.
RUN wget -P /opt --progress=bar:force https://www.fil.ion.ucl.ac.uk/spm/download/restricted/bids/spm${SPM_VERSION}_${SPM_REVISION}_Linux_${MATLAB_VERSION}.zip \
 && unzip -q /opt/spm${SPM_VERSION}_${SPM_REVISION}_Linux_${MATLAB_VERSION}.zip -d /opt \
 && rm -f /opt/spm${SPM_VERSION}_${SPM_REVISION}_Linux_${MATLAB_VERSION}.zip \
 && find /opt/spm${SPM_VERSION}/ -name '*mexw32*' -name '*mexw64*' -name '*mexmaci64*' -delete \
 && /opt/spm${SPM_VERSION}/spm${SPM_VERSION} function exit \
 && chmod +x /opt/spm${SPM_VERSION}/${SPM_VERSION}

# Configure entry point
ENTRYPOINT ["/opt/spm12/spm12"]
CMD ["--help"]
