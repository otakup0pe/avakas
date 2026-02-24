FROM python:3.12-alpine

ARG VERSION=0.0.0

ENV SSH_SCAN_HOST="github.com"

LABEL license="MIT"
LABEL version="${VERSION}"
LABEL maintainer="Jonathan Freedman <jonafree@gmail.com>"

COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

RUN apk add --no-cache git openssh

COPY . /tmp/avakas
COPY scripts/docker-entrypoint /usr/local/bin/docker-entrypoint

RUN uv venv /opt/avakas && \
    uv pip install --python /opt/avakas/bin/python /tmp/avakas && \
    rm -rf /tmp/avakas

ENTRYPOINT ["docker-entrypoint"]
