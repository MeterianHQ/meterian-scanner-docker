# Helper images 'import' for bin copy/installation
FROM melopt/alpine-perl-devel:latest as perlBin

FROM rust:1.53.0-alpine3.12 as rustBin

FROM alpine:3.12 as binariesStash

ARG DOTNET_VERSION=3.1.410
ARG DOTNET_DOWNLOAD_SHA="d844e044d7dfbca0b69913c3d5a5dde0f46ddf4a43c1e8c2a474dc65c3089521d0e946507ede4654efc4281314360c66f5c477ee90e1e80f30115e7a5aa1b586"

ARG SCALA_VERSION=2.13.6
ARG SBT_VERSION=1.5.3

WORKDIR /binaries/

# DOTNET bin
RUN mkdir -p dotnet \
 && wget -q "https://download.visualstudio.microsoft.com/download/pr/7212036d-2481-4cb3-87d3-b559a21f0c34/1953e788344059b0c279879b2ba559e7/dotnet-sdk-${DOTNET_VERSION}-linux-musl-x64.tar.gz"
## Here it's important to keep two spaces between the sha and the download to match sha512sum output
RUN echo "${DOTNET_DOWNLOAD_SHA}  /binaries/dotnet-sdk-${DOTNET_VERSION}-linux-musl-x64.tar.gz" | sha512sum -c -
RUN tar -xzf dotnet-sdk-${DOTNET_VERSION}-linux-musl-x64.tar.gz -C dotnet

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


# DOTNET install
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT="1"
COPY --from=binariesStash /binaries/dotnet/ /usr/lib/dotnet
RUN min-apk-add libstdc++ libintl \
 && ln -s /usr/lib/dotnet/dotnet /usr/bin/dotnet \
 && source /etc/profile


# PERL (plus carton) install
ENV PERL5LIB=/app/lib:/app/local/lib/perl5:/deps/local/lib/perl5:/stack/local/lib/perl5
COPY --from=perlBin /usr/lib/perl5/ /usr/lib/perl5/
COPY --from=perlBin /usr/bin/perl /usr/bin/perl
COPY --from=perlBin /usr/local/bin/carton /usr/local/bin/carton
COPY --from=perlBin /usr/share/perl5/ /usr/share/perl5/
COPY --from=perlBin /usr/local/share/perl5/ /usr/local/share/perl5/
COPY --from=perlBin /usr/local/share/man/ /usr/local/share/man/
COPY --from=perlBin /usr/local/lib/perl5/ /usr/local/lib/perl5/
COPY --from=perlBin /usr/local/bin/cpanm /usr/local/bin/cpanm
COPY --from=perlBin /usr/bin/cpan /usr/bin/cpan
COPY --from=perlBin /usr/bin/perl5.26.3 /usr/bin/perl5.26.3
# later versions of make don't work with carton for some reason
RUN min-apk-add make=4.2.1-r2 --repository=http://dl-cdn.alpinelinux.org/alpine/v3.9/main


# Ruby install
ARG RUBY_VERSION=2.7.3-r0
RUN min-apk-add build-base ruby-dev=${RUBY_VERSION} ruby-full=${RUBY_VERSION}


# Swift (Cocoapods) install
RUN min-apk-add git \
 && min-gem-install cocoapods


# PHP (Composer) install
RUN min-apk-add php7 php-json php-phar php-iconv php-openssl --repository=http://dl-cdn.alpinelinux.org/alpine/v3.12/main \
 && curl -sS https://getcomposer.org/installer -o composer-setup.php \
 && php composer-setup.php --install-dir=/usr/local/bin --filename=composer \
 && rm composer-setup.php


# GO install
ENV GOROOT /usr/lib/go
RUN min-apk-add go


# NodeJS (npm) install
RUN min-apk-add npm=12.22.1-r0


# SCALA install
ENV PATH=${PATH}:/usr/local/sbt/bin
COPY --from=binariesStash /binaries/scala/ /usr/share/scala/
COPY --from=binariesStash /binaries/sbt/ /usr/local/sbt/
# installing min version supported of bash only for scala and sbt that require it
RUN min-apk-add bash=5.0.0-r0 --repository=http://dl-cdn.alpinelinux.org/alpine/v3.10/main \
 && ln -s /usr/share/scala/bin/scala /usr/bin/scala


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


# Python install (ref: https://github.com/nbgallery/jupyter-alpine/)
RUN echo "### Install specific version of zeromq from source" \
 && min-package https://archive.org/download/zeromq_4.0.4/zeromq-4.0.4.tar.gz \
 && ln -s /usr/local/lib/libzmq.so.3 /usr/local/lib/libzmq.so.4 \
 && strip --strip-unneeded --strip-debug /usr/local/bin/curve_keygen \
 && echo "### Alpine compatibility patch for various packages" \
 && if [ ! -f /usr/include/xlocale.h ]; then echo '#include <locale.h>' > /usr/include/xlocale.h; fi \
 && rm -rf /usr/local/share/man/*/zmq* \
 && rm -rf /usr/include/c++/*/java \
 && rm -rf /usr/include/c++/*/javax \
 && rm -rf /usr/include/c++/*/gnu/awt \
 && rm -rf /usr/include/c++/*/gnu/classpath \
 && rm -rf /usr/include/c++/*/gnu/gcj \
 && rm -rf /usr/include/c++/*/gnu/java \
 && rm -rf /usr/include/c++/*/gnu/javax \
 && rm -rf /usr/libexec/gcc/x86_64-alpine-linux-musl/*/cc1obj \
 && rm -rf /usr/bin/gcov* \
 && rm -rf /usr/bin/gprof \
 && rm -rf /usr/bin/*gcj \
 && min-apk-add python3 py3-pip python3-dev python2 libffi-dev \
 && min-pip3-install --ignore-installed distlib pipenv pipreqs jupyter


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
