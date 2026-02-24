"""
Avakas Built-In PEP 621 Project Flavor
"""

import os

import tomlkit

from avakas.flavors.base import AvakasLegacy
from avakas.avakas import register_flavor


@register_flavor('pep621')
class AvakasP621Project(AvakasLegacy):
    """
    PEP 621 pyproject.toml Avakas Project Flavor
    """
    PROJECT_TYPE = 'pep621'

    @classmethod
    def guess_flavor(cls, directory):
        pyproject = os.path.join(directory, 'pyproject.toml')
        if not os.path.exists(pyproject):
            return False
        with open(pyproject, 'r', encoding='utf8') as f:
            doc = tomlkit.parse(f.read())
        return 'version' in doc.get('project', {})

    def __pyproject_path(self):
        return os.path.join(self.directory, 'pyproject.toml')

    def __read_pyproject(self):
        with open(self.__pyproject_path(), 'r', encoding='utf8') as f:
            return tomlkit.parse(f.read())

    def __write_pyproject(self, doc):
        with open(self.__pyproject_path(), 'w', encoding='utf8') as f:
            f.write(tomlkit.dumps(doc))

    def read(self):
        doc = self.__read_pyproject()
        self.version = doc['project']['version']
        return True

    def write(self):
        self.check_if_dirty()
        doc = self.__read_pyproject()
        doc['project']['version'] = str(self._version)
        self.__write_pyproject(doc)
        self.commit_files = ['pyproject.toml']
        self.write_git()
