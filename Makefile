.PHONY: all testenv install package test test_unit test_integration \
	test_in_containers test_in_container_312 test_in_container_310 \
	test_container_entrypoint generate_testing_artifact lint-secrets \
	clean distclean container

HERE := $(shell pwd)
GITLEAKS_IMAGE ?= ghcr.io/gitleaks/gitleaks:v8.30.1@sha256:c00b6bd0aeb3071cbcb79009cb16a60dd9e0a7c60e2be9ab65d25e6bc8abbb7f
GITLEAKS_MODE ?= git
GITLEAKS_SOURCE ?= .

SETUP_CONTAINER_FOR_TESTS := mkdir -p /tmp/avakas && \
	tar -c --exclude=.git --exclude=.ci-env --exclude='.bats*' -C /src . | tar -x -C /tmp/avakas && \
	cd /tmp/avakas && \
	pip install -t /tmp/avakas/.ci-env -r requirements.txt -r requirements-dev.txt

ifndef CI
	CI_ENV=$(HERE)/.ci-env/bin/
endif

all: test package

testenv:
ifndef CI
	echo "Outside CI"
	test -d .ci-env || ( mkdir .ci-env && virtualenv -p python3 .ci-env) && .ci-env/bin/python3 -m pip install --upgrade pip
	.ci-env/bin/pip install -r requirements.txt -r requirements-dev.txt --upgrade
endif
ifdef CI
	echo "Within CI"
	pip install -r requirements.txt -r requirements-dev.txt
endif

install: testenv
	$(CI_ENV)python -m pip install $(shell pwd)

package:
	$(CI_ENV)python -m build

test_unit: testenv install
	$(CI_ENV)python -m unittest discover -s tests/unit

test_integration: testenv install
	AVAKAS_PYTHON="$(CI_ENV)python" ./scripts/integration $(TEST)

test: lint-secrets testenv install
	$(CI_ENV)coverage erase
	$(CI_ENV)pycodestyle "avakas"
	$(CI_ENV)pylint "avakas"
	$(CI_ENV)coverage run -a --source "avakas" -m unittest discover -s tests/unit
	AVAKAS_PYTHON="$(CI_ENV)python" ./scripts/integration
	$(CI_ENV)coverage report -m
	test -z $(TRAVIS) && $(CI_ENV)coverage erase || true

generate_testing_artifact: testenv
	$(CI_ENV)python -m build --sdist

test_in_container_312: generate_testing_artifact
	docker run -u nobody -v "$(HERE):/src" python:3.12 sh -c '$(SETUP_CONTAINER_FOR_TESTS) && PYTHONPATH=/tmp/avakas/.ci-env /tmp/avakas/.ci-env/bin/tox -e py312'

test_in_container_310: generate_testing_artifact
	docker run -u nobody -v "$(HERE):/src" python:3.10 sh -c '$(SETUP_CONTAINER_FOR_TESTS) && PYTHONPATH=/tmp/avakas/.ci-env /tmp/avakas/.ci-env/bin/tox -e py310'


test_container_entrypoint:
	bash ./scripts/container-integration

test_in_containers: test_in_container_312 test_in_container_310 test_container_entrypoint

lint-secrets:
	docker run --rm \
		--user "$$(id -u):$$(id -g)" \
		--network none \
		--read-only \
		--cap-drop=ALL \
		--tmpfs /tmp:rw,noexec,nosuid,size=16m \
		-v "$(HERE):/repo:ro" \
		-w /repo \
		$(GITLEAKS_IMAGE) $(GITLEAKS_MODE) $(GITLEAKS_SOURCE) --redact --no-banner --verbose

clean:
	rm -rf .bats-git .bats .ci-env avakas.egg-info dist build .coverage .tox

distclean: clean
	rm -rf .bats-git .ci-env

container:
	docker build \
		--tag otakup0pe/avakas:local \
		.
