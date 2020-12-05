"""
Avakas Built-In Nodejs Project Flavor
"""

import json
import os

from avakas.flavors.base import AvakasLegacy
from avakas.avakas import register_flavor


@register_flavor('node')
class AvakasNodeProject(AvakasLegacy):
    """
    Nodejs Avakas Project Flavor
    """
    PROJECT_TYPE = 'node'

    @classmethod
    def guess_flavor(cls, directory):
        return os.path.exists("%s/package.json" % directory)

    def __read_package_json(self):
        manifest = os.path.join(self.directory, 'package.json')
        manifest_file = open(manifest, 'r')
        manifest_json = json.load(manifest_file)
        manifest_file.close()

        return manifest_json

    def __write_package_json(self, manifest_dict):
        manifest = os.path.join(self.directory, 'package.json')
        manifest_file = open(manifest, 'w')
        json.dump(manifest_dict,
                  manifest_file,
                  indent=4,
                  separators=(',', ': '),
                  sort_keys=True)
        manifest_file.close()

    @classmethod
    def __extract_version(cls, manifest_json):
        return manifest_json['version']

    def read(self):
        manifest = self.__read_package_json()
        self.version = self.__extract_version(manifest)

    def write(self):
        manifest = self.__read_package_json()
        manifest['version'] = self.version
        self.__write_package_json(manifest)
