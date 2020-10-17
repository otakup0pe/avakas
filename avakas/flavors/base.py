"""
Avakas Built-In Base Project Flavor
"""

from functools import cmp_to_key
import os
import subprocess
from semantic_version import compare as semver_compare

from avakas.errors import AvakasError
from avakas.avakas import register_flavor


@register_flavor('default')
class AvakasProject():
    """
    Default Avakas Project Flavor
    """
    PROJECT_TYPE = 'default'

    def __init__(self, **kwargs):
        self.options = kwargs.get('opt', {})
        self.tag_prefix = self.options.get('tag_prefix', 'v')
        self.version_filename = self.options.get('filename', 'version')
        if self.version_filename is None:
            self.version_filename = 'version'
        self.directory = kwargs.get('directory', os.getcwd())

    @classmethod
    def guess_flavor(cls):
        """
        Return true if determined this is the project's flavor.
        For example, current directory has a meta/version file,
        return a true value.
        """
        # default should always return false
        return False

    def get_version(self):
        """
        Get the version from the current project flavor
        """
        path = os.path.join(self.directory, self.version_filename)
        version_file = open(path, 'r')
        version = version_file.read()
        version_file.close()
        return version

    def set_version(self, version):
        """
        Set the version for the current project flavor
        """
        path = os.path.join(self.directory, self.version_filename)
        version_file = open(path, 'w')
        version = version_file.write("%s\n" % str(version))
        version_file.close()


@register_flavor('git')
class AvakasGitProject(AvakasProject):
    """
    Version Control System Avakas Project
    """
    PROJECT_TYPE = 'git'

    def __run_cmd(self, command, success=0):
        result = subprocess.run(
            command.split(' '),
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            cwd=self.directory if self.directory is not None else None,
            shell=False,
            check=True,
        )
        output = result.stdout.decode().strip()
        if result.returncode is not success:
            raise AvakasError(
                "The command '{}' returned code {}. Output:\n{}".format(
                    command, result.returncode, output
                )
            )
        return output

    def get_version(self):
        msg = self.__run_cmd('git tag --merged HEAD --sort -creatordate')
        if not msg:
            raise AvakasError('Unable to find a version tag')
        tags = msg.splitlines()
        fixed_tags = [t.lstrip('v') for t in tags]
        sorted_versions = sorted(fixed_tags, key=cmp_to_key(semver_compare))

        return sorted_versions[-1]

    def set_version(self, version):
        pass
