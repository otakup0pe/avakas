ifndef TRAVIS
	CI_ENV=$(shell pwd)/.ci-env/bin/
endif

all: test package

testenv:
	test -z $(TRAVIS) && (test -d .ci-env || ( mkdir .ci-env && virtualenv .ci-env )) || true
	test -z $(TRAVIS) && \
		(echo "Non Travis" && .ci-env/bin/pip install -r requirements.txt -r requirements-dev.txt --upgrade) || \
		(echo "Travis" && pip install -r requirements.txt -r requirements-dev.txt)

package:
	python setup.py sdist

test: testenv
	coverage erase
	$(CI_ENV)pep8 "avakas"
	$(CI_ENV)pylint "avakas"
	./scripts/ci
	coverage report -m
	test -z $(TRAVIS) && coverage erase || true

clean:
	rm -rf .bats-git .bats .ci-env avakas.egg-info dist build

container:
	./scripts/container
