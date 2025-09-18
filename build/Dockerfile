# Helper images 'import' for bin copy/installation
FROM rust:1.53.0-alpine3.12 as rustBin

FROM alpine:3.17.2 as binariesStash

ARG SCALA_VERSION=2.13.10
ARG SBT_VERSION=1.9.0

WORKDIR /binaries/

# SCALA bin
RUN mkdir -p scala sbt \
 && apk --no-cache add curl \
 && curl -sS https://downloads.lightbend.com/scala/${SCALA_VERSION}/scala-${SCALA_VERSION}.tgz -o scala-${SCALA_VERSION}.tgz \
 && tar xzf scala-${SCALA_VERSION}.tgz -C scala --strip-components=1
RUN wget -q https://github.com/sbt/sbt/releases/download/v${SBT_VERSION}/sbt-${SBT_VERSION}.tgz
RUN tar xzf sbt-${SBT_VERSION}.tgz -C sbt --strip-components=1




# Final image build steps
FROM alpine:3.17.2
COPY ./alpine/util/* /usr/local/bin/


# General setup
RUN apk update \
 && min-apk-add apk-tools>2.10.7-r0 binutils curl>7.77.0-r0 coreutils git openssh \
 && apk upgrade musl


# JAVA install
ARG MAVEN_VERSION=3.8.6-r0
ARG GRADLE_VERSION=8.0.2
ENV PATH=${PATH}:/opt/gradle/gradle-${GRADLE_VERSION}/bin/
RUN min-apk-add openjdk17 --repository=http://dl-cdn.alpinelinux.org/alpine/v3.15/community \
 && min-apk-add maven=${MAVEN_VERSION} --repository=http://dl-cdn.alpinelinux.org/alpine/v3.13/community \
 && curl -sSL https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-all.zip --output /tmp/gradle-${GRADLE_VERSION}-all.zip \
 && mkdir -p /opt/gradle; unzip -d /opt/gradle /tmp/gradle-${GRADLE_VERSION}-all.zip; rm /tmp/gradle-${GRADLE_VERSION}-all.zip


# Ant specifics
ENV ANT_HOME=/usr/share/ant
ENV PATH=${PATH}:${ANT_HOME}/bin
ARG ANT_VERSION=1.10.14
ARG IVY_VERSION=2.5.1
RUN wget -q -O /tmp/apache-ant-${ANT_VERSION}-bin.tar.gz https://dlcdn.apache.org//ant/binaries/apache-ant-${ANT_VERSION}-bin.tar.gz \
 && mkdir -p /usr/share/ant \
 && tar xzf /tmp/apache-ant-${ANT_VERSION}-bin.tar.gz -C /usr/share/ant --strip-components=1 \
 && wget -q -O ${ANT_HOME}/lib/ivy.jar https://repo1.maven.org/maven2/org/apache/ivy/ivy/${IVY_VERSION}/ivy-${IVY_VERSION}.jar \
 && ln -s /usr/share/ant/bin/ant /usr/bin/ant \
 && rm /tmp/apache-ant-${ANT_VERSION}-bin.tar.gz \
 && ant -version; echo

# ivy patch for gradle
RUN cp ${ANT_HOME}/lib/ivy.jar /opt/gradle/gradle-${GRADLE_VERSION}/lib/plugins/ivy-2.3.0.jar


# DOTNET install
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT="1"
RUN min-apk-add bash icu-dev gcc libstdc++ libintl exiftool \
 && wget -q -O /tmp/dotnet-install.sh https://dotnet.microsoft.com/download/dotnet/scripts/v1/dotnet-install.sh \
 && chmod +x /tmp/dotnet-install.sh \
 && mkdir -p /usr/lib/dotnet/; /tmp/dotnet-install.sh --install-dir /usr/lib/dotnet/ --version 8.0.101 \
 && /tmp/dotnet-install.sh --install-dir /usr/lib/dotnet/ --version 6.0.418 \
 && ln -s /usr/lib/dotnet/dotnet /usr/bin/dotnet \
 && rm /tmp/dotnet-install.sh


# PERL (plus carton) install
ARG MOD_PERL2_SHA="890dca0950847e32180485cabbeffbf236af2c92c7df957a233c210022b5172957eddb1db3e9281b87cd438d2fa404a05ae99c7eda098267c68d5e9262b400b0"
RUN min-apk-add perl-dev wget build-base zlib-dev expat-dev libxml2-dev perl-test-harness-utils=3.42-r1 --repository=http://dl-cdn.alpinelinux.org/alpine/v3.12/main \
 # later versions of make don't work with carton for some reason
 && min-apk-add make=4.2.1-r2 --repository=http://dl-cdn.alpinelinux.org/alpine/v3.9/main \
 && min-apk-add ncurses-dev readline-dev perl-net-ssleay openssl gd-dev libjpeg-turbo-dev apr-util-dev=1.6.1-r6 openldap-dev=2.4.58-r0 apache2-dev=2.4.53-r0 mariadb-client --repository=http://dl-cdn.alpinelinux.org/alpine/v3.12/main \
 # mod_perl2 module installation (https://perl.apache.org/download/)
 && wget -q -O /tmp/mod_perl-2.0.12.tar.gz https://dlcdn.apache.org/perl/mod_perl-2.0.12.tar.gz \
 && echo "${MOD_PERL2_SHA}  /tmp/mod_perl-2.0.12.tar.gz" | sha512sum -c - \
 && tar -xvzf /tmp/mod_perl-2.0.12.tar.gz -C /tmp > /dev/null 2>&1 \
 && PREV_DIR=$(pwd); cd /tmp/mod_perl-2.0.12 \
 && perl Makefile.PL > /dev/null 2>&1 \
 && make > /dev/null 2>&1 \
 && make install > /dev/null 2>&1 \
 && cd $PREV_DIR; rm -rf /tmp/mod_perl-2.0.12.tar.gz /tmp/mod_perl-2.0.12 \
 # carton and cpanm installations
 && curl -L https://cpanmin.us | perl - App::cpanminus \
 && cpanm -n -q Carton App::cpm \
 && rm -rf ~/.cpanm


# Ruby install
ARG RUBY_VERSION=3.1.5-r0
RUN min-apk-add build-base ruby-dev=${RUBY_VERSION} ruby-full=${RUBY_VERSION} --repository=http://dl-cdn.alpinelinux.org/alpine/v3.17/main


# Swift (Cocoapods) install
RUN min-apk-add linux-headers \
 && min-gem-install activesupport -v 7.0.5 \
 && min-gem-install cocoapods -v 1.12.1 \
 && pod --allow-root --version


# PHP (Composer) install
RUN min-apk-add php81 php81-phar drupal7 \
 && curl -sS https://getcomposer.org/installer -o composer-setup.php \
 && php composer-setup.php --install-dir=/usr/local/bin --filename=composer \
 && rm composer-setup.php


# GO install
ENV GOROOT /usr/lib/go
RUN min-apk-add go --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community


# NodeJS (npm) install
ARG NODE_PACKAGE_URL=https://unofficial-builds.nodejs.org/download/release/v20.10.0/node-v20.10.0-linux-x64-musl.tar.gz

RUN min-apk-add libstdc++
RUN wget -O /tmp/node-v20.10.0-linux-x64-musl.tar.gz ${NODE_PACKAGE_URL}
RUN mkdir -p /opt/nodejs
RUN tar -xzf /tmp/node-v20.10.0-linux-x64-musl.tar.gz --directory /opt/nodejs --strip-components=1
RUN rm /tmp/node-v20.10.0-linux-x64-musl.tar.gz
RUN ln -s /opt/nodejs/bin/node /usr/local/bin/node
RUN ln -s /opt/nodejs/bin/npm /usr/local/bin/npm
RUN npm install -g npm@10.2.4
RUN min-apk-add yarn


# SCALA install
ENV PATH=${PATH}:/usr/local/sbt/bin
COPY --from=binariesStash /binaries/scala/ /usr/share/scala/
COPY --from=binariesStash /binaries/sbt/ /usr/local/sbt/
RUN min-apk-add bash --repository=http://dl-cdn.alpinelinux.org/alpine/v3.10/main \
 && ln -s /usr/share/scala/bin/scala /usr/bin/scala


# Rust install
ENV PATH=${PATH}:/opt/rust/cargo/bin \
    RUSTUP_HOME=/opt/rust/rustup
COPY --from=rustBin /usr/local/cargo/ /opt/rust/cargo
COPY --from=rustBin /usr/local/rustup/toolchains/1.53.0-x86_64-unknown-linux-musl/bin/cargo /opt/rust/rustup/toolchains/1.53.0-x86_64-unknown-linux-musl/bin/cargo
# install the standard toolchain for the current arch in minimal profile (as of now this installs cargo, rust-std & rustc) and remove rust-std
RUN rustup set profile minimal \
 && rustup toolchain install stable || true \
 && rustup component remove rust-std


# Python install
ARG REPOS="--repository=http://dl-cdn.alpinelinux.org/alpine/v3.15/community --repository=http://dl-cdn.alpinelinux.org/alpine/v3.15/main --repository=http://dl-cdn.alpinelinux.org/alpine/v3.21/main"
RUN min-apk-add g++ openblas-dev=0.3.18-r1 cmake openssl-libs-static openssl-dev ${REPOS}

ENV PATH=${PATH}:/opt/python/3.12.6/bin
RUN min-apk-add "musl>=1.2.3"
RUN wget -q -P /tmp/ https://www.python.org/ftp/python/3.12.6/Python-3.12.6.tgz
RUN tar xvf /tmp/Python-3.12.6.tgz -C /tmp/ && rm /tmp/Python-3.12.6.tgz
RUN mkdir -p /opt/python/3.12.6
RUN mkdir python3 && cd python3
RUN /tmp/Python-3.12.6/configure --prefix=/opt/python/3.12.6
RUN make -C .
RUN make install
RUN ln -s /opt/python/3.12.6/bin/python3 /usr/bin/python
RUN cd .. && rm -r python3 && rm -r /tmp/Python-3.12.6
RUN min-apk-add "zeromq-dev>=4.3.4-r0" "gdal-dev>=3.4.3-r0" "libxslt-dev>=1.1.35-r0" ${REPOS}
RUN min-apk-add g++ openblas-dev=0.3.18-r1 cmake openssl-libs-static openssl-dev ${REPOS}

RUN curl https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py
RUN python3 /tmp/get-pip.py --break-system-packages && rm /tmp/get-pip.py
COPY ./python-specific/pip/pip.conf /etc/
RUN pip --version

RUN min-apk-add linux-headers \
 && min-pip3-install --ignore-installed distlib pipenv pipreqs jupyter


# Conan install
RUN pip3 install conan==1.65.0


# R and renv install
RUN min-apk-add R R-dev \
 && R --slave -e "install.packages('renv', repos='http://cran.r-project.org')" \
 && R --slave -e "packageVersion('renv')"


# Clojure specifics
RUN min-apk-add rlwrap=0.45.2-r1 --repository=http://dl-cdn.alpinelinux.org/alpine/v3.16/community \
 && curl -o /usr/local/bin/lein https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein \
 && chmod a+x /usr/local/bin/lein \
 && lein \
 && curl -o /tmp/posix-install-1.11.1.1208.sh https://download.clojure.org/install/posix-install-1.11.1.1208.sh \
 && chmod +x /tmp/posix-install-1.11.1.1208.sh \
 && /tmp/posix-install-1.11.1.1208.sh \
 && rm /tmp/posix-install-1.11.1.1208.sh


# Python poetry specifics
RUN python3 -m venv /usr/lib/pythonEnvs/forPoetry \
 && /usr/lib/pythonEnvs/forPoetry/bin/pip install -U pip setuptools \
 && /usr/lib/pythonEnvs/forPoetry/bin/pip install -U pip poetry \
 && ln -s /usr/lib/pythonEnvs/forPoetry/bin/poetry /usr/bin/poetry \
 && poetry --version


# Python UV specifics
RUN pip install uv


# Adding shadow to allow the meterian user creation with uid/gid matching host see https://github.com/MeterianHQ/meterian-scanner-docker/issues/19
RUN min-apk-add shadow


# Meterian client Download
RUN wget -q -O /tmp/meterian-cli-www.jar https://www.meterian.com/downloads/meterian-cli.jar


### Setup dockerized version stamp
ARG VERSION
RUN test -n "${VERSION}"
RUN echo "" >> /root/version.txt
RUN echo "© 2017-2024 Meterian Ltd - dockerized version ${VERSION}" >> /root/version.txt

# Vuln patches
RUN apk del apache2-dev
RUN apk del apr-util-dev
RUN apk del openldap-dev


### Final entrypoint setup
WORKDIR /root
COPY ./*.sh ./
ENTRYPOINT ["/root/entrypoint.sh"]
