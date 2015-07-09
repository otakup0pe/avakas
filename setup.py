#!/usr/bin/env python
import sys, os

try:
    from setuptools import setup
except ImportError:
    print("avakas requires setuptools")
    sys.exit(1)

setup(name='avakas',
      version='0.0.1',
      description='Interact with project version metadata',
      author='Jonathan Freedman',
      author_email='jonafree@gmail.com',
      url='https://github.com/otakup0pe/avakas',
      install_requires=['semantic_version'],
      scripts=[
          'avakas'
      ])
