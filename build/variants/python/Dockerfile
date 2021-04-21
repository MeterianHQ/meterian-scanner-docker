FROM openjdk:11.0.10-jdk-buster

SHELL ["/bin/bash", "-o", "pipefail", "-c"]


### General setup
RUN  apt-get update \
  && apt-get -y install apt-transport-https apt-utils


## Python install
RUN apt-get update \
  && apt-get install -qy python-pip \
  && pip -V \
  && pip install pipenv \
  && pipenv --version \
  && apt install -qy python-backports.functools-lru-cache \
  && apt install -qy python3-distutils \
  && apt install -qy python3-pip \
  && pip3 install jupyter \
  && pip3 install pipreqs \
  && pip3 install pipenv


### Setup initial meterian client (it will be updated if required)
RUN curl -o /tmp/meterian-cli.jar -O -J -L https://www.meterian.com/downloads/meterian-cli.jar


### Setup dockerize version stamp
ARG VERSION
RUN test -n "${VERSION}"
RUN  echo "© 2017-2020 Meterian Ltd - dockerized version ${VERSION}" > /root/version.txt


### Final entrypoint setup
WORKDIR /root
COPY ./*.sh ./
ENTRYPOINT ["/root/entrypoint.sh"]


### Removing vulnerable components, also they are not used for the purpose of this image
RUN apt-get remove -qy mercurial wget

