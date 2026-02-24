.PHONY = all testenv install package test test_in_containers test_in_container_312 test_in_container_313 clean container

HERE := $(shell pwd)

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

test: testenv install
	$(CI_ENV)coverage erase
	$(CI_ENV)pycodestyle "avakas"
	$(CI_ENV)pylint "avakas"
	./scripts/integration
	$(CI_ENV)coverage report -m
	test -z $(TRAVIS) && $(CI_ENV)coverage erase || true

generate_testing_artifact: testenv
	$(CI_ENV)tox --sdistonly

test_in_container_312: generate_testing_artifact
	docker run -u nobody -v "$(HERE):/src" python:3.12 sh -c '$(SETUP_CONTAINER_FOR_TESTS) && PYTHONPATH=/tmp/avakas/.ci-env /tmp/avakas/.ci-env/bin/tox -e py312'

test_in_container_310: generate_testing_artifact
	docker run -u nobody -v "$(HERE):/src" python:3.10 sh -c '$(SETUP_CONTAINER_FOR_TESTS) && PYTHONPATH=/tmp/avakas/.ci-env /tmp/avakas/.ci-env/bin/tox -e py310'


# Long term these versions should not be hardcoded, upon
# viability of the tox-via-docker plugin, that should be used.
test_in_containers: test_in_container_312 test_in_container_310

clean:
	rm -rf .bats-git .bats .ci-env avakas.egg-info dist build .coverage .tox

distclean: clean
	rm -rf .bats-git .ci-env

container:
	docker build \
		--tag otakup0pe/avakas:local \
		.
