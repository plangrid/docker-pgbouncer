FROM        ubuntu:16.04

ARG         ARTIFACTORY_USER
ARG         ARTIFACTORY_PASSWORD

ENV         PGBOUNCER_VERSION=1.7.2-2.pgdg16.04+1 \
            ARTIFACTORY_USER='read-only' \
            ARTIFACTORY_PASSWORD='UN5cDIG5EyJdDrc5EBwB'

# Prep apt
# Using /usr/bin/apt-get here because these are dependencies we need for our
# custom apt-get to work
RUN         ln -sf /bin/bash /bin/sh \
            && /usr/bin/apt-get update \
            && /usr/bin/apt-get install -y \
                apt-transport-https \
                ca-certificates \
                curl \
                locales \
                wget \
                gnupg \
            # make sure en_US.UTF-8 is installed
            && locale-gen en_US.UTF-8 \
            # cleanup
            && /usr/bin/apt-get clean \
            && /usr/bin/apt-get autoremove

# Artifactory apt repo
RUN         echo "deb https://${ARTIFACTORY_USER}:${ARTIFACTORY_PASSWORD}@plangrid.jfrog.io/plangrid/debs-local xenial main" > /etc/apt/sources.list.d/artifactory.list \
            && curl -u ${ARTIFACTORY_USER}:${ARTIFACTORY_PASSWORD} https://plangrid.jfrog.io/plangrid/api/gpg/key/public \
            | apt-key add -

RUN         set -x \
            && apt-get -qq update \
            && apt-get install -yq --no-install-recommends pgbouncer=$PGBOUNCER_VERSION \
            && apt-get purge -y --auto-remove \
            && rm -rf /var/lib/apt/lists/*

ADD         entrypoint.sh ./

EXPOSE      5432

CMD  ["./entrypoint.sh"]
RUN echo 'app-git-hash: e9d78dfcd463e101898234bbefc1aa2ebe8746f1' >> /etc/docker-metadata
