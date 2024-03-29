# Helper images 'import' for bin copy/installation
FROM rust:1.53.0-alpine3.12 as rustBin




# Final image build steps
FROM alpine:3.12
COPY ./alpine/util/* /usr/local/bin/


# General setup
RUN apk update \
 && min-apk-add binutils curl coreutils git openssh \
 && apk upgrade musl


# JAVA install
RUN min-apk-add openjdk17 --repository=http://dl-cdn.alpinelinux.org/alpine/v3.15/community


# Rust install
ENV PATH=${PATH}:/opt/rust/cargo/bin \
    RUSTUP_HOME=/opt/rust/rustup
COPY --from=rustBin /usr/local/cargo/ /opt/rust/cargo
COPY --from=rustBin /usr/local/rustup/toolchains/1.53.0-x86_64-unknown-linux-musl/bin/cargo /opt/rust/rustup/toolchains/1.53.0-x86_64-unknown-linux-musl/bin/cargo
# install the standard toolchain for the current arch in minimal profile (as of now this installs cargo, rust-std & rustc) and remove rust-std
RUN rustup set profile minimal \
 && rustup toolchain install stable || true \
 && rustup component remove rust-std


# Adding shadow to allow the meterian user creation with uid/gid matching host see https://github.com/MeterianHQ/meterian-scanner-docker/issues/19
RUN min-apk-add shadow \
 && min-apk-add bash=5.0.17-r0 --repository=http://dl-cdn.alpinelinux.org/alpine/v3.10/main


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
