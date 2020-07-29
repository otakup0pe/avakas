FROM python:3.8-alpine

MAINTAINER 'Jonathan Freedman <jonafree@gmail.com>'
ARG VERSION=0.0.0

ENV SSH_SCAN_HOST="github.com"

LABEL license="MIT"
LABEL version="${VERSION}"

RUN mkdir "/etc/avakas"

ADD . /tmp/avakas
ADD scripts/docker-entrypoint /usr/local/bin/docker-entrypoint

RUN cd /tmp/avakas && python setup.py install && cd /tmp && rm -rf /tmp/avakas

ENTRYPOINT ["docker-entrypoint"]
