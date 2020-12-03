"""
Avakas Built-In Ansible Project Flavor
"""

import sys
import os

from avakas.flavors.base import AvakasGitProject
from avakas.avakas import register_flavor


@register_flavor('ansible')
class AvakasAnsibleProject(AvakasGitProject):
    """
    Ansible Avakas Project
    """
    PROJECT_TYPE = 'ansible'

    def __init__(self, **kwargs):
        opt = kwargs.get('opt', {})
        tag_prefix = opt.get('tag_prefix', 'v')
        # Handle explicit None
        tag_prefix = 'v' if tag_prefix is None else tag_prefix
        if tag_prefix != 'v':
            print('Problem: Cannot specify a tag prefix with an Ansible Role')
            sys.exit(1)
        super().__init__(**kwargs)

    def guess_flavor(self):
        return os.path.exists("%s/meta/main.yml" % self.directory)

    def set_version(self, version):
        # write to version file
        path = os.path.join(self.directory, self.version_filename)
        version_file = open(path, 'w')
        version_file.write("v%s\n" % str(version))
        version_file.close()
        # set git tag
        super().set_version(version)
