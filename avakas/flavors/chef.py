"""
Avakas Built-In Chef Project Flavor
"""

import os
import re

from avakas.flavors.base import AvakasLegacy
from avakas.avakas import register_flavor
from avakas.errors import AvakasError
from avakas.utils import match_and_rewrite_lines


@register_flavor('chef')
class AvakasChefProject(AvakasLegacy):
    """
    Chef Cookbook Avakas Project Flavor
    """
    PROJECT_TYPE = 'chef'

    @classmethod
    def guess_flavor(cls, directory):
        return os.path.exists("%s/metadata.rb" % directory)

    def __read_metadata_file(self):
        handle = open("%s/metadata.rb" % self.directory, 'r')
        data = handle.read()
        return data, handle

    def read(self):
        """Extract the version from Chef Cookbook metadata"""
        data, handle = self.__read_metadata_file()
        pattern = r'^version.+["\'](?P<vsn>\d+\.\d+\.\d+)["\'].*'
        matcher = re.compile(pattern, re.MULTILINE)
        vsn_match = matcher.search(data)
        handle.close()
        self.version = str(vsn_match.group('vsn'))
        return True

    def write(self):
        """Writes the version to metadata.rb"""

        self.check_if_dirty()

        pattern = r'^(version.+["\'])(\d+\.\d+\.\d+)(["\'].*)'
        data, handle = self.__read_metadata_file()
        rewritten, updated = match_and_rewrite_lines(pattern, data,
                                                     str(self.version))

        if not updated:
            raise AvakasError('Unable to set version on metadata.rb')

        handle = open("%s/metadata.rb" % self.directory, 'w')
        handle.write(rewritten)
        handle.close()

        self.write_versionfile()

        self.write_git()
