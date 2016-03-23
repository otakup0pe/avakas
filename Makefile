all: test package

package:
	python setup.py sdist

test:
	./scripts/ci

clean:
	rm -rf .bats-git .bats .ci-env avakas.egg-info dist
