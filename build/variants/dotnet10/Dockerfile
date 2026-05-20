FROM alpine:3.17.2
COPY ./alpine/util/* /usr/local/bin/


# General setup
RUN apk update \
 && min-apk-add binutils curl coreutils git openssh \
 && apk upgrade musl


# JAVA install
RUN min-apk-add openjdk17 --repository=http://dl-cdn.alpinelinux.org/alpine/v3.15/community


# DOTNET install
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT="1"
RUN min-apk-add bash icu-dev gcc libstdc++ libintl exiftool \
 && wget -q -O /tmp/dotnet-install.sh https://dotnet.microsoft.com/download/dotnet/scripts/v1/dotnet-install.sh \
 && chmod +x /tmp/dotnet-install.sh \
 && mkdir -p /usr/lib/dotnet/; /tmp/dotnet-install.sh --install-dir /usr/lib/dotnet/ --version 10.0.300 \
 && ln -s /usr/lib/dotnet/dotnet /usr/bin/dotnet \
 && rm /tmp/dotnet-install.sh


# Adding shadow to allow the meterian user creation with uid/gid matching host see https://github.com/MeterianHQ/meterian-scanner-docker/issues/19
RUN min-apk-add shadow \
 && min-apk-add bash --repository=http://dl-cdn.alpinelinux.org/alpine/v3.10/main


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
