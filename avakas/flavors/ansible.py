"""
Avakas Built-In Ansible Project Flavor
"""

import os

from git import Git

from avakas.flavors.base import AvakasLegacy
from avakas.avakas import register_flavor
from avakas.errors import AvakasError
from avakas.utils import sort_versions


@register_flavor('ansible')
class AvakasAnsibleProject(AvakasLegacy):
    """
    Ansible Avakas Project
    """
    PROJECT_TYPE = 'ansible'

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        tag_prefix = self.options.get('tag_prefix', '')
        if tag_prefix not in ['v', '']:
            raise AvakasError('Cannot specify a tag prefix '
                              'with an Ansible Role')
        self.options['tag_prefix'] = 'v'

    @classmethod
    def guess_flavor(cls, directory):
        return os.path.exists("%s/meta/main.yml" % directory)

    def read(self):
        git = Git(self.directory)
        out = git.tag(merged="HEAD", sort="-creatordate")
        tags = out.splitlines()
        tags = [t.strip(self.options['tag_prefix']) for t in tags]
        tags = sort_versions(tags)
        latest_tag = tags[-1]

        self.version = latest_tag

        return self.version
