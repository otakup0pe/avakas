"""
Avakas Built-In Ansible Project Flavor
"""

import sys
import os

from avakas.flavors.base import AvakasProject, AvakasGitProject
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
        AvakasProject.set_version(self, "v%s" % version)
        super().set_version("v%s" % version)
