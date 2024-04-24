ARG DOCKER_VERSION=26.1.0

FROM docker:${DOCKER_VERSION}-dind AS docker_image

FROM joeniland/laravel-ci:latest

USER root

ENV DOCKER_TLS_CERTDIR=/certs
RUN mkdir /certs /certs/client && chmod 1777 /certs /certs/client

# Get docker executables from official dind image
COPY --from=docker_image /usr/local/bin/ /usr/local/bin/
COPY --from=docker_image /usr/local/libexec/docker/cli-plugins /usr/local/libexec/docker/cli-plugins

COPY dockerd-entrypoint.sh /usr/local/bin/

VOLUME /var/lib/docker

ENTRYPOINT ["dockerd-entrypoint.sh"]
CMD []

HEALTHCHECK --interval=10s --timeout=60s --start-period=5s --retries=3 CMD [ "docker info >/dev/null 2>&1" ]
