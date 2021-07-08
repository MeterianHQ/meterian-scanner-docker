FROM alpine:3.12
COPY ./alpine/util/* /usr/local/bin/


# General setup
RUN min-apk-add binutils curl coreutils


# JAVA install
RUN min-apk-add openjdk11


# Ruby install
ARG RUBY_VERSION=2.7.3-r0
RUN min-apk-add build-base ruby-dev=${RUBY_VERSION} ruby-full=${RUBY_VERSION}


# Adding shadow to allow the meterian user creation with uid/gid matching host see https://github.com/MeterianHQ/meterian-scanner-docker/issues/19
RUN min-apk-add shadow


# Meterian client Download
RUN wget -q -O /tmp/meterian-cli-www.jar https://www.meterian.com/downloads/meterian-cli.jar


### Setup dockerized version stamp
ARG VERSION
RUN test -n "${VERSION}"
RUN echo "" >> /root/version.txt
RUN echo "© 2017-2021 Meterian Ltd - dockerized version ${VERSION}" >> /root/version.txt


### Final entrypoint setup
WORKDIR /root
COPY ./*.sh ./
ENTRYPOINT ["/root/entrypoint.sh"]
