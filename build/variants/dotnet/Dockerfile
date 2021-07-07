# Helper images 'import' for bin copy/installation
FROM alpine:3.12 as binariesStash

ARG DOTNET_VERSION=3.1.410
ARG DOTNET_DOWNLOAD_SHA="d844e044d7dfbca0b69913c3d5a5dde0f46ddf4a43c1e8c2a474dc65c3089521d0e946507ede4654efc4281314360c66f5c477ee90e1e80f30115e7a5aa1b586"

WORKDIR /binaries/

# DOTNET bin
RUN mkdir -p dotnet \
 && wget -q "https://download.visualstudio.microsoft.com/download/pr/7212036d-2481-4cb3-87d3-b559a21f0c34/1953e788344059b0c279879b2ba559e7/dotnet-sdk-${DOTNET_VERSION}-linux-musl-x64.tar.gz"
## Here it's important to keep two spaces between the sha and the download to match sha512sum output
RUN echo "${DOTNET_DOWNLOAD_SHA}  /binaries/dotnet-sdk-${DOTNET_VERSION}-linux-musl-x64.tar.gz" | sha512sum -c -
RUN tar -xzf dotnet-sdk-${DOTNET_VERSION}-linux-musl-x64.tar.gz -C dotnet




# Final image build steps
FROM alpine:3.12
COPY ./alpine/util/* /usr/local/bin/


# General setup
RUN min-apk-add binutils curl coreutils


# JAVA install
RUN min-apk-add openjdk11


# DOTNET install
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT="1"
COPY --from=binariesStash /binaries/dotnet/ /usr/lib/dotnet
RUN min-apk-add libstdc++ libintl \
 && ln -s /usr/lib/dotnet/dotnet /usr/bin/dotnet \
 && source /etc/profile


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
