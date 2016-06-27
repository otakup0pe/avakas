FROM python:2.7

ADD . /tmp/avakas

RUN cd /tmp/avakas && python setup.py install

ENTRYPOINT ["/usr/local/bin/avakas"]
