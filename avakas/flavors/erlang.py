"""
Avakas Built-In Erlang Project Flavor
"""

from glob import glob
from erl_terms import decode as erl_decode

from avakas.flavors.base import AvakasProject
from avakas.avakas import register_flavor
from avakas.errors import AvakasError
from avakas.utils import match_and_rewrite_lines


@register_flavor('erlang')
class AvakasErlangProject(AvakasProject):
    """
    Erlang Avakas Project Flavor
    """
    PROJECT_TYPE = 'erlang'

    def guess_flavor(self):
        return len(glob("%s/src/*.app.src" % self.directory)) == 1

    def get_version(self):
        app_file = glob("%s/src/*.app.src" % self.directory)[0]
        version_handle = open(app_file, 'r')
        erl_terms = erl_decode(version_handle.read())
        version_handle.close()
        app_config = erl_terms[0][2]
        erlang_version = None
        for config in app_config:
            if config[0] == 'vsn':
                erlang_version = config[1]

        if not erlang_version:
            raise AvakasError('Unable to determine Erlang version')

        return erlang_version

    def set_version(self, version):
        app_file = glob("%s/src/*.app.src" % self.directory)[0]
        app_handle = open(app_file, 'r')
        lines, updated = match_and_rewrite_lines(r'(.+vsn.+")(.+)(".+)',
                                                 app_handle, version)
        app_handle.close()
        if not updated:
            raise AvakasError('Unable to save Erlang version')

        app_handle = open(app_file, 'w')
        app_handle.write(''.join(lines))
        app_handle.close()
