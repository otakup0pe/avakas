all: test package

deps:
	poetry install

package:
	test -f version || poetry version $(cat version)
	test -f version || poetry build

test:
	coverage erase
	pycodestyle "avakas"
	pylint "avakas"
	./scripts/integration
	coverage report -m
	test -z $(TRAVIS) && coverage erase || true

install:
	poetry install

clean:
	rm -rf .bats-git .bats .ci-env avakas.egg-info dist build .coverage
	python setup.py clean

container:
	docker build \
		--tag otakup0pe/avakas:local \
		.
