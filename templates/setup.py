#!/usr/bin/env python
import sys

# Reminder: Template Generated
try:
    from setuptools import setup
except ImportError:
    print("avakas requires setuptools")
    sys.exit(1)

def main():
    version = '@@VERSION@@'

    setup(name='avakas',
          version=version,
          description='Interact with project version metadata',
          author='Jonathan Freedman',
          author_email='jonafree@gmail.com',
          license='MIT',
          url='https://github.com/otakup0pe/avakas',
          install_requires=['semantic_version', 'gitpython'],
          packages=['avakas', 'avakas.flavors'],
          entry_points={
            'console_scripts': ['avakas = avakas.cli:main']
          },
          include_package_data=True)


if __name__ == "__main__":
    main()
