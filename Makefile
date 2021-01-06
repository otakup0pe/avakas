.PHONY = all testenv install package test test_in_containers test_in_container_37 test_in_container_38 clean container

HERE := $(shell pwd)

ifndef CI
	CI_ENV=$(HERE)/.ci-env/bin/
endif


all: test package

testenv:
	test -z $(CI) && (test -d .ci-env || ( mkdir .ci-env && virtualenv -p python3 .ci-env )) || true
	test -z $(CI) && \
		(echo "Outside CI" && .ci-env/bin/pip install -r requirements.txt -r requirements-dev.txt --upgrade) || \
		(echo "Within CI" && pip install -r requirements.txt -r requirements-dev.txt)

install:
	python -m avakas show . --flavor "git-native"
	python setup.py install

package:
	python setup.py sdist

test: testenv install
	$(CI_ENV)coverage erase
	$(CI_ENV)pycodestyle "avakas"
	$(CI_ENV)pylint "avakas"
	./scripts/integration
	$(CI_ENV)coverage report -m
	test -z $(TRAVIS) && $(CI_ENV)coverage erase || true

generate_testing_artifact: clean
	tox --sdistonly

test_in_container_37: #generate_testing_artifact
	docker run -v "$(HERE):/src" python:3.7 bash -c 'pip install tox; cd /src;tox -e py37'

test_in_container_38: generate_testing_artifact
	docker run -v "$(HERE):/src" python:3.8 bash -c 'pip install tox; cd /src;tox -e py38'


# Long term these versions should not be hardcoded, upon
# viability of the tox-via-docker plugin, that should be used.
test_in_containers: test_in_container_37 test_in_container_38


clean:
	rm -rf .bats-git .bats .ci-env avakas.egg-info dist build .coverage .tox
	python setup.py clean

container:
	docker build \
		--tag otakup0pe/avakas:local \
		.
