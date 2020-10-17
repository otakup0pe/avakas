"""
Avakas Built-In Chef Project Flavor
"""

import os
import re

from avakas.flavors.base import AvakasProject
from avakas.avakas import register_flavor
from avakas.errors import AvakasError
from avakas.utils import match_and_rewrite_lines


@register_flavor('chef')
class AvakasChefProject(AvakasProject):
    """
    Chef Cookbook Avakas Project Flavor
    """
    PROJECT_TYPE = 'chef'

    def guess_flavor(self):
        return os.path.exists("%s/metadata.rb" % self.directory)

    def get_version(self):
        """Extract the version from Chef Cookbook metadata"""
        metadata_handle = open("%s/metadata.rb" % self.directory, 'r')
        metadata = metadata_handle.read()
        metadata_handle.close()
        pattern = r'^version.+["\'](?P<vsn>\d+\.\d+\.\d+)["\'].*'
        vsn_match = re.compile(pattern, re.MULTILINE).search(metadata)
        return str(vsn_match.group('vsn'))

    def set_version(self, version):
        """Writes the version to metadata.rb"""
        metadata_file = "%s/metadata.rb" % self.directory
        metadata_handle = open(metadata_file, 'r')

        pattern = r'^(version.+["\'])(\d+\.\d+\.\d+)(["\'].*)'
        lines, updated = match_and_rewrite_lines(pattern, metadata_handle,
                                                 version)

        metadata_handle.close()
        if not updated:
            raise AvakasError('Unable to set version on metadata.rb')

        metadata_handle = open(metadata_file, 'w')
        metadata_handle.write(''.join(lines))
        metadata_handle.close()
        super().set_version(version)
