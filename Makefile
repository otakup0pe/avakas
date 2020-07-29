ifndef CI
	CI_ENV=$(shell pwd)/.ci-env/bin/
endif

all: test package

testenv:
	test -z $(CI) && (test -d .ci-env || ( mkdir .ci-env && virtualenv .ci-env )) || true
	test -z $(CI) && \
		(echo "Outside CI" && .ci-env/bin/pip install -r requirements.txt -r requirements-dev.txt --upgrade) || \
		(echo "Within CI" && pip install -r requirements.txt -r requirements-dev.txt)


test -d .ci-env || ( mkdir .ci-env && virtualenv .ci-env )
	.ci-env/bin/pip install -r requirements.txt -r requirements-dev.txt --upgrade

package:
	python setup.py sdist

test: testenv
	$(CI_ENV)coverage erase
	$(CI_ENV)pep8 "avakas"
	$(CI_ENV)pylint "avakas"
	./scripts/ci
	$(CI_ENV)coverage report -m
	test -z $(TRAVIS) && $(CI_ENV)coverage erase || true

clean:
	rm -rf .bats-git .bats .ci-env avakas.egg-info dist build .coverage

container:
	./scripts/container
