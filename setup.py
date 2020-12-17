#!/usr/bin/env python
import sys
import os
from avakas.avakas import detect_project_flavor


try:
    from setuptools import setup
except ImportError:
    print("avakas requires setuptools")
    sys.exit(1)


def main():
    project = detect_project_flavor(flavor='git-native',
                                    directory=[os.getcwd()],
                                    filename='version',
                                    tag_prefix="")
    project.read()
    version = project.version

    setup(name='avakas',
          version=version,
          description='Interact with project version metadata',
          author='Jonathan Freedman',
          author_email='jonafree@gmail.com',
          license='MIT',
          url='https://github.com/otakup0pe/avakas',
          install_requires=['semantic_version', 'gitpython', 'erl_terms'],
          packages=['avakas', 'avakas.flavors'],
          entry_points={
            'console_scripts': ['avakas = avakas.cli:main']
          },
          include_package_data=True,
          package_data={'avakas': [
            'version'
          ]})


if __name__ == "__main__":
    main()
