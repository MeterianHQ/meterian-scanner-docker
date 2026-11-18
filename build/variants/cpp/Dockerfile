FROM alpine:3.12
COPY ./alpine/util/* /usr/local/bin/


# General setup
RUN apk update \
 && min-apk-add binutils curl coreutils git openssh \
 && apk upgrade musl


# JAVA install
RUN min-apk-add openjdk17 --repository=http://dl-cdn.alpinelinux.org/alpine/v3.15/community


# Python install
RUN min-apk-add libstdc++ python3 python3-dev python2 libffi-dev python2-dev zeromq-dev gdal-dev \
 && min-apk-add g++ zlib-dev openblas-dev cmake openssl-libs-static openssl-dev \
 && curl https://bootstrap.pypa.io/pip/3.8/get-pip.py -o /tmp/get-pip.py \
 && python3 /tmp/get-pip.py \
 && rm /tmp/get-pip.py

# Conan install
RUN pip3 install conan==1.60.2


# vcpkg install
# A full clone, not a shallow clone: vcpkg reads old port versions from the git
# history ("builtin-baseline" and "overrides" in vcpkg.json). On Alpine, the
# bootstrap script downloads the musl binary, and vcpkg must use the system
# cmake and ninja (VCPKG_FORCE_SYSTEM_BINARIES). vcpkg needs CMake 3.21 or
# later, and Alpine 3.12 has 3.17: thus cmake comes from Alpine 3.15. The
# client runs as the "meterian" user with the host uid, and vcpkg writes into
# its root folder: thus all users can write the root folder, and git accepts
# it as safe.
ARG VCPKG_VERSION=2026.10.16
ENV VCPKG_ROOT=/opt/vcpkg \
    VCPKG_FORCE_SYSTEM_BINARIES=1 \
    VCPKG_DISABLE_METRICS=1
RUN min-apk-add "cmake>=3.21" --repository=http://dl-cdn.alpinelinux.org/alpine/v3.15/main \
 && min-apk-add build-base ninja zip unzip curl git tar pkgconf perl linux-headers \
 && git clone https://github.com/microsoft/vcpkg.git ${VCPKG_ROOT} \
 && git -C ${VCPKG_ROOT} checkout -q ${VCPKG_VERSION} \
 && ${VCPKG_ROOT}/bootstrap-vcpkg.sh -disableMetrics \
 && ln -s ${VCPKG_ROOT}/vcpkg /usr/local/bin/vcpkg \
 && chmod -R a+rwX ${VCPKG_ROOT} \
 && git config --system --add safe.directory ${VCPKG_ROOT} \
 && vcpkg version

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
