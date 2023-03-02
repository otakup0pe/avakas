"""
Avakas Built-In Ansible Project Flavor
"""

import os

from avakas.flavors.git import AvakasGitNative
from avakas.avakas import register_flavor
from avakas.errors import AvakasError


@register_flavor('ansible')
class AvakasAnsibleProject(AvakasGitNative):
    """
    Ansible Avakas Project
    """
    PROJECT_TYPE = 'ansible'

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        if self.tag_prefix not in ['v', '']:
            raise AvakasError('Cannot specify a tag prefix '
                              'with an Ansible Role')

    @classmethod
    def guess_flavor(cls, directory):
        return os.path.exists(f"{directory}/meta/main.yml")
