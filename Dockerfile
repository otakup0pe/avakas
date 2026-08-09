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

# Support non-root usage: create writable home at /avakas-home.
# When run with -u UID:GID, the user has no /etc/passwd entry and
# HOME defaults to /. This gives a predictable writable HOME.
RUN mkdir -p /avakas-home/.ssh && \
    chmod a+rwx /avakas-home && \
    chmod a+rwx /avakas-home/.ssh
ENV HOME=/avakas-home

ENTRYPOINT ["docker-entrypoint"]
