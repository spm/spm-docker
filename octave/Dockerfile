FROM ubuntu:cosmic

MAINTAINER Guillaume Flandin <g.flandin@ucl.ac.uk>

RUN apt-get update && apt-get -y install \
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
 && curl -SL https://github.com/spm/spm12/archive/r7219.tar.gz \
  | tar -xzC /opt/spm12 --strip-components 1 \
 && make -C /opt/spm12/src PLATFORM=octave distclean \
 && make -C /opt/spm12/src PLATFORM=octave \
 && make -C /opt/spm12/src PLATFORM=octave install \
 && ln -s /opt/spm12/bin/spm12-octave /usr/local/bin/spm12

#RUN octave --no-gui --eval "addpath (\"/opt/spm12\"); savepath ();"

ENTRYPOINT ["spm12"]

CMD ["--help"]