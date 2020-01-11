.PHONY: env test package clean distclean
ifndef VIRTUAL_ENV
CIENV = $(shell pwd)/.venv/bin/
else
CIENV = $(VIRTUAL_ENV)/bin/
endif

all: test package

env:
	test -z $(VIRTUAL_ENV) && (test -d .venv || ( mkdir .venv && virtualenv .venv)) || true
	test -d artifacts || ( mkdir artifacts ) || true
	test -z $(VIRTUAL_ENV) && (.venv/bin/pip install -r requirements.txt -r requirements-dev.txt --upgrade) || \
		( pip install -r requirements.txt -r requirements-dev.txt)

package:
	python setup.py sdist

test: env
	$(CIENV)tox

distclean: clean
	rm -rf .bats-git .bats .ci-env .tox .venv

clean:
	rm -rf avakas.egg-info dist build .coverage

container:
	./scripts/container
