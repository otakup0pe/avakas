"""
Avakas Built-In Erlang Project Flavor
"""

import re
from glob import glob

from avakas.flavors.base import AvakasLegacy
from avakas.avakas import register_flavor
from avakas.errors import AvakasError
from avakas.utils import match_and_rewrite_lines


@register_flavor('erlang')
class AvakasErlangProject(AvakasLegacy):
    """
    Erlang Avakas Project Flavor
    """
    PROJECT_TYPE = 'erlang'

    @classmethod
    def guess_flavor(cls, directory):
        return len(glob(f"{directory}/src/*.app.src")) == 1

    def read(self):
        app_file = glob(f"{self.directory}/src/*.app.src")[0]
        with open(app_file, 'r', encoding='utf8') as version_handle:
            app_data = version_handle.read()
            version_handle.close()
            vsn_regex = re.compile(r'^(.+vsn.+")(.+)(".+)$', re.MULTILINE)
            if not vsn_regex(app_data):
                raise AvakasError('Unable to determine Erlang version')

            self.version = vsn_regex[2]
            return self.version

    def write(self):
        app_file = glob(f"{self.directory}/src/*.app.src")[0]
        with open(app_file, 'r', encoding='utf8') as app_handle:
            lines, updated = match_and_rewrite_lines(r'(.+vsn.+")(.+)(".+)',
                                                     app_handle, self.version)
            app_handle.close()
            if not updated:
                raise AvakasError('Unable to save Erlang version')

            with open(app_file, 'w', encoding='utf8') as app_handle:
                app_handle.write(''.join(lines))
                app_handle.close()
