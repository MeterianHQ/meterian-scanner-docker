# Helper images 'import' for bin copy/installation
FROM alpine:3.12 as binariesStash

ARG SCALA_VERSION=2.13.6
ARG SBT_VERSION=1.5.3

WORKDIR /binaries/

# SCALA bin
RUN mkdir -p scala sbt \
 && apk --no-cache add curl \
 && curl -sS https://downloads.lightbend.com/scala/${SCALA_VERSION}/scala-${SCALA_VERSION}.tgz -o scala-${SCALA_VERSION}.tgz \
 && tar xzf scala-${SCALA_VERSION}.tgz -C scala --strip-components=1
RUN wget -q https://github.com/sbt/sbt/releases/download/v${SBT_VERSION}/sbt-${SBT_VERSION}.tgz
RUN tar xzf sbt-${SBT_VERSION}.tgz -C sbt --strip-components=1




# Final image build steps
FROM alpine:3.12
COPY ./alpine/util/* /usr/local/bin/


# General setup
RUN min-apk-add binutils curl coreutils


# JAVA install
ARG MAVEN_VERSION=3.6.3-r0
ARG GRADLE_VERSION=6.7.1-r0
RUN min-apk-add openjdk11 maven=${MAVEN_VERSION} \
 && min-apk-add gradle=${GRADLE_VERSION} --repository=http://dl-cdn.alpinelinux.org/alpine/v3.13/community


# SCALA install
ENV PATH=${PATH}:/usr/local/sbt/bin
COPY --from=binariesStash /binaries/scala/ /usr/share/scala/
COPY --from=binariesStash /binaries/sbt/ /usr/local/sbt/
# installing min version supported of bash only for scala and sbt that require it
RUN min-apk-add bash=5.0.0-r0 --repository=http://dl-cdn.alpinelinux.org/alpine/v3.10/main \
 && ln -s /usr/share/scala/bin/scala /usr/bin/scala 


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
