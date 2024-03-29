FROM docker/compose:1.24.1 AS docker-compose
FROM docker:18.09 AS docker

FROM amazeeio/php:7.2-cli-drupal

LABEL maintainer="govcms@finance.gov.au"
LABEL description="GovCMS base image for use in CI processes"

RUN apk update \
  && apk add --no-cache \
      zip \
      zlib \
      libgcc \
  && apk add --no-cache -t .deps ca-certificates \
  && wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub \
  && wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.29-r0/glibc-2.29-r0.apk \
  && apk add glibc-2.29-r0.apk \
  && rm -rf /var/cache/apk/* \
  && apk del --purge .deps \
  && composer clear-cache \
  && rm -rf /app

# Required for docker-compose to find zlib.
ENV LD_LIBRARY_PATH=/lib:/usr/lib

COPY --from=docker /usr/local/bin/docker /bin
COPY --from=docker-compose /usr/local/bin/docker-compose /usr/local/bin/docker-compose

# Install yq for YAML parsing
RUN wget -O /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/download/2.4.0/yq_linux_amd64" \
  && chmod +x /usr/local/bin/yq

# Install jq for JSON parsing
RUN wget -O /usr/local/bin/jq "https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64" \
  && chmod +x /usr/local/bin/jq

# Install Ahoy.
RUN wget -O /usr/local/bin/ahoy "https://github.com/ahoy-cli/ahoy/releases/download/2.0.0/ahoy-bin-linux-amd64" \
  && chmod +x /usr/local/bin/ahoy

# Install Goss (and dgoss) for server validation.
ENV GOSS_FILES_STRATEGY=cp
RUN wget -O /usr/local/bin/goss https://github.com/aelsabbahy/goss/releases/download/v0.3.6/goss-linux-amd64 \
  && chmod +x /usr/local/bin/goss \
  && wget -O /usr/local/bin/dgoss https://raw.githubusercontent.com/aelsabbahy/goss/master/extras/dgoss/dgoss \
  && chmod +x /usr/local/bin/dgoss

# Install a stub for pygmy.
# Some frameworks may require presence of pygmy to run, but pygmy is not required in CI container.
RUN touch /usr/local/bin/pygmy \
  && chmod +x /usr/local/bin/pygmy

RUN git --version \
  && ssh -V \
  && zip --version \
  && unzip -v \
  && curl --version \
  && jq --version \
  && yq --version \
  && ahoy --version \
  && goss --version \
  && docker --version \
  && docker-compose version \
  && composer --version \
  && npm -v \
  && node -v
