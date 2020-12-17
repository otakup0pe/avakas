#!/usr/bin/env python
import sys
import os
import subprocess
from avakas.avakas import detect_project_flavor


try:
    from setuptools import setup
except ImportError:
    print("avakas requires setuptools")
    sys.exit(1)


def main():
    try:
        resp = subprocess.run(['git', 'branch', '--show-current'],
                              capture_output=True,
                              encoding='UTF-8')
        current_branch = str(resp.stdout.strip())
        subprocess.call(['git', 'branch', '--show-current'])
        project = detect_project_flavor(flavor='git-native',
                                        directory=[os.getcwd()],
                                        filename='version',
                                        branch=current_branch,
                                        tag_prefix="")
        project.read()
        version = project.version
    except Exception:
        version = '0.0.0'
        print('Avakas was unable to determine version. Using %s' % version,
              file=sys.stderr)

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
