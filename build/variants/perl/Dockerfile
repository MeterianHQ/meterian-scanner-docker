# Helper images 'import' for bin copy/installation
FROM melopt/alpine-perl-devel:latest as perlBin




# Final image build steps
FROM alpine:3.12
COPY ./alpine/util/* /usr/local/bin/


# General setup
RUN min-apk-add binutils curl coreutils


# JAVA install
RUN min-apk-add openjdk11


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
