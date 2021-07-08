# Helper images 'import' for bin copy/installation
FROM rust:1.53.0-alpine3.12 as rustBin




# Final image build steps
FROM alpine:3.12
COPY ./alpine/util/* /usr/local/bin/


# General setup
RUN min-apk-add binutils curl coreutils


# JAVA install
RUN min-apk-add openjdk11


# Rust install
ENV PATH=${PATH}:/opt/rust/cargo/bin \
    RUSTUP_HOME=/opt/rust/rustup \
    CARGO_HOME=/opt/rust/cargo
COPY --from=rustBin /usr/local/cargo/ /opt/rust/cargo
COPY --from=rustBin /usr/local/rustup/toolchains/1.53.0-x86_64-unknown-linux-musl/bin/cargo /opt/rust/rustup/toolchains/1.53.0-x86_64-unknown-linux-musl/bin/cargo
# install the standard toolchain for the current arch in minimal profile (as of now this installs cargo, rust-std & rustc) and remove all components but cargo
RUN chmod 777 /opt/rust/ -R \
 && rustup set profile minimal \
 && rustup toolchain install stable || true \
 && set -ex; components="$(rustup component list --toolchain stable | grep installed | cut -d' ' -f1)" \
 && for component in $components; do [[ "$(echo "$component" | grep -o cargo)" == "" ]] && rustup component remove $component; done


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
