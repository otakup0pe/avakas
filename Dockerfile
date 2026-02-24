FROM python:3.12-alpine

ARG VERSION=0.0.0

ENV SSH_SCAN_HOST="github.com"

LABEL license="MIT"
LABEL version="${VERSION}"
LABEL maintainer="Jonathan Freedman <jonafree@gmail.com>"

RUN apk add --no-cache git openssh

COPY . /tmp/avakas
COPY scripts/docker-entrypoint /usr/local/bin/docker-entrypoint

RUN pip install --upgrade pip && pip install virtualenv && virtualenv /opt/avakas && \
    /opt/avakas/bin/pip install /tmp/avakas && \
    rm -rf /tmp/avakas

ENTRYPOINT ["docker-entrypoint"]
