.PHONY = all testenv install package test test_in_containers test_in_container_37 test_in_container_38 clean container version

HERE := $(shell pwd)
HERE_OWNERSHIP := $(shell stat -c '%u:%g' $(HERE))
FIX_OWNERSHIP := chown -R $(HERE_OWNERSHIP)

SETUP_CONTAINER_FOR_TESTS := cd /src;pip install -r requirements.txt

ifndef CI
	CI_ENV=$(HERE)/.ci-env/bin/
endif


all: test package

testenv:
	test -z $(CI) && (test -d .ci-env || ( mkdir .ci-env && virtualenv -p python3 .ci-env )) || true
	test -z $(CI) && \
		(echo "Outside CI" && .ci-env/bin/pip install -r requirements.txt -r requirements-dev.txt --upgrade) || \
		(echo "Within CI" && pip install -r requirements.txt -r requirements-dev.txt)

version: testenv
	(CI_ENV)python -m avakas show . --flavor "git-native" --branch $$(git branch --show-current)

install: testenv version
	$(CI_ENV)python setup.py install

package:
	python setup.py sdist

test: testenv install
	$(CI_ENV)coverage erase
	$(CI_ENV)pycodestyle "avakas"
	$(CI_ENV)pylint "avakas"
	./scripts/integration
	$(CI_ENV)coverage report -m
	test -z $(TRAVIS) && $(CI_ENV)coverage erase || true

generate_testing_artifact: version
	tox --sdistonly

test_in_container_37: generate_testing_artifact
	docker run -v "$(HERE):/src" python:3.7 bash -c '$(SETUP_CONTAINER_FOR_TESTS); tox -e py37;$(FIX_OWNERSHIP) /src'

test_in_container_38: generate_testing_artifact
	docker run -v "$(HERE):/src" python:3.8 bash -c '$(SETUP_CONTAINER_FOR_TESTS);tox -e py38;$(FIX_OWNERSHIP) /src'


# Long term these versions should not be hardcoded, upon
# viability of the tox-via-docker plugin, that should be used.
test_in_containers: test_in_container_37 test_in_container_38

clean:
	# The touch and remove is because the setup.py depends on a file existing
	# which isn't actually tracked in git
	touch version
	rm -rf .bats-git .bats .ci-env avakas.egg-info dist build .coverage .tox
	python setup.py clean
	rm version

container:
	docker build \
		--tag otakup0pe/avakas:local \
		.
