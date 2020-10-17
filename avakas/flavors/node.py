"""
Avakas Built-In Nodejs Project Flavor
"""

import json
import os

from avakas.flavors.base import AvakasProject
from avakas.avakas import register_flavor


@register_flavor('node')
class AvakasNodeProject(AvakasProject):
    """
    Nodejs Avakas Project Flavor
    """
    PROJECT_TYPE = 'node'

    @classmethod
    def __read_package_json(cls, directory):
        manifest = os.path.join(directory, 'package.json')
        manifest_file = open(manifest, 'r')
        manifest_json = json.load(manifest_file)
        manifest_file.close()

        return manifest_json

    @classmethod
    def __write_package_json(cls, directory, manifest_dict):
        manifest = os.path.join(directory, 'package.json')
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

    def guess_flavor(self):
        return os.path.exists("%s/package.json" % self.directory)

    def get_version(self):
        manifest = self.__read_package_json(self.directory)
        return self.__extract_version(manifest)

    def set_version(self, version):
        manifest = self.__read_package_json(self.directory)
        manifest['version'] = version
        self.__write_package_json(self.directory, manifest)
