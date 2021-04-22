FROM openjdk:11.0.10-jdk-buster

### Variables
ARG DOTNET_VERSION=3.1
ARG MAVEN_VERSION=3.6.3
ARG PHP_VERSION=7.2
ARG NODE_VERSION=12.x
ARG GRADLE_VERSION=6.1
ARG GO_VERSION=1.14.1

SHELL ["/bin/bash", "-o", "pipefail", "-c"]


### General setup
RUN  apt-get update \
  && apt-get -y install apt-transport-https apt-utils


### Dotnet sdk install
RUN  wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.asc.gpg \
  && mv microsoft.asc.gpg /etc/apt/trusted.gpg.d/ \
  && wget -q https://packages.microsoft.com/config/debian/9/prod.list \
  && mv prod.list /etc/apt/sources.list.d/microsoft-prod.list \
  && chown root:root /etc/apt/trusted.gpg.d/microsoft.asc.gpg \
  && chown root:root /etc/apt/sources.list.d/microsoft-prod.list \
  && apt-get update \
  && apt-get -y install dotnet-sdk-${DOTNET_VERSION} \
  && wget -q https://packages.microsoft.com/config/ubuntu/19.04/packages-microsoft-prod.deb -O /tmp/packages-microsoft-prod.deb \
  && dpkg -i /tmp/packages-microsoft-prod.deb \
  && rm /tmp/packages-microsoft-prod.deb


### Maven install
RUN mkdir -p /usr/share/maven /usr/share/maven/ref \
  && curl -fsSL -o /tmp/apache-maven.tar.gz https://apache.osuosl.org/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
  && tar -xzf /tmp/apache-maven.tar.gz -C /usr/share/maven --strip-components=1 \
  && rm -f /tmp/apache-maven.tar.gz \
  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn


## PHP install
RUN apt install -qy apt-transport-https lsb-release ca-certificates \
  && wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg \
  && echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list \
  && apt update \
  && apt -qy install php${PHP_VERSION} \
  && php -v \
  && apt update \
  && apt -qy install php${PHP_VERSION}-mbstring \
  && curl -sS https://getcomposer.org/installer -o /tmp/composer-setup.php \
  && php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer \
  && rm /tmp/composer-setup.php \
  && composer --version


## Ruby install
RUN apt-get update \ 
  && apt-get install -qy ruby \
  && ruby -v \
  && gem install bundler \
  && bundle -v \
  && gem install bundler -v "~>1.0"

  
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


### Node install
RUN apt-get install -qy software-properties-common \
  && curl -sL https://deb.nodesource.com/setup_${NODE_VERSION} | bash -\
  && apt-get install -qy nodejs \
  && node -v


## Gradle install
ENV GRADLE_USER_HOME ~/.gradle
ENV GRADLE_HOME /opt/gradle/gradle-${GRADLE_VERSION}
ENV PATH $GRADLE_HOME/bin:$PATH
RUN wget -q https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip -P /tmp \
  && unzip -d /opt/gradle /tmp/gradle-*.zip \
  && gradle -v \
  && rm /tmp/gradle* 


## Scala install
RUN apt-get install -qy scala \
  && scala -version \
  && echo "deb https://dl.bintray.com/sbt/debian /" >> /etc/apt/sources.list.d/sbt.list \
  && curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2EE0EA64E40A89B84B2DF73499E82A75642AC823" | apt-key add \
  && apt-get update \
  && apt-get install -qy sbt


## Go install
ENV GOROOT /usr/local/go
ENV PATH $GOROOT/bin:$PATH
RUN wget -q https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz -P /tmp \
  && tar -xzf /tmp/go${GO_VERSION}.linux-amd64.tar.gz -C /usr/local \
  && go version \
  && rm -f /tmp/go${GO_VERSION}*


## Swift install
RUN apt-get install -qy ruby ruby-dev build-essential\
  && ruby -v \
  && gem install cocoapods \
  && gem which cocoapods | grep -oh cocoapods-[0-9\.]* \
  && apt-get remove -qy build-essential \
  && apt -qy autoremove


### Rust install
RUN curl https://sh.rustup.rs -sSf | env RUSTUP_HOME=/opt/rust/rustup CARGO_HOME=/opt/rust/cargo sh -s -- --default-toolchain stable --profile default --no-modify-path -y


### Setup initial meterian client (it will be updated if required)
RUN curl -o /tmp/meterian-cli-www.jar -O -J -L https://www.meterian.com/downloads/meterian-cli.jar


### Setup dockerize version stamp
ARG VERSION
RUN test -n "${VERSION}"
RUN echo "" >> /root/version.txt
RUN echo "© 2017-2020 Meterian Ltd - dockerized version ${VERSION}" >> /root/version.txt


### Final entrypoint setup
WORKDIR /root
COPY ./*.sh ./
ENTRYPOINT ["/root/entrypoint.sh"]


### Removing vulnerable components, also they are not used for the purpose of this image
RUN apt-get remove -qy mercurial wget

