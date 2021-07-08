FROM alpine:3.12
COPY ./alpine/util/* /usr/local/bin/


# General setup
RUN min-apk-add binutils curl coreutils


# JAVA install
RUN min-apk-add openjdk11


# Python install (ref: https://github.com/nbgallery/jupyter-alpine/)
RUN echo "### Install specific version of zeromq from source" \
 && min-apk-add make=4.2.1-r2 build-base --repository=http://dl-cdn.alpinelinux.org/alpine/v3.9/main \
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
