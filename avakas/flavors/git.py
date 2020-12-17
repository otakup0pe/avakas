"""
Avakas Built-In Base Project Flavor
"""

import re
import os

from git import Repo, Git

from avakas.errors import AvakasError
from avakas.avakas import Avakas, register_flavor
from avakas.utils import sort_versions


@register_flavor('git-native')
class AvakasGitNative(Avakas):
    """
    Avakas Git Native - using tags only
    Similar to thorscmversion
    """
    PROJECT_TYPE = 'git-native'

    @classmethod
    def guess_flavor(cls, directory):
        """
        Always return false as this is an explicitly called
        flavor.
        """
        # pylint: disable=unused-argument
        return False

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.version_filename = kwargs['filename']
        self.repo = self.__load_git()

    def __load_git(self):
        """Initializes our local git workspace."""
        repo = Repo(self.directory, search_parent_directories=True)
        if not repo:
            raise AvakasError("Unable to find associated git repo for %s." %
                              self.directory)

        return repo

    def __git_push(self, tag):
        """Push git tag if remote exists"""
        opt = self.options
        if opt['remote'] not in [r.name for r in self.repo.remotes]:
            return

        if tag:
            remote = self.repo.remote(name=opt['remote'])
            resp = remote.push(tag)[0]

        if resp.flags & 1024 or resp.flags & 32 or resp.flags & 16:
            raise AvakasError("Unexpected git error: %s" % resp.summary)

    def __create_git_tag(self):
        """Creates a git tag"""
        return self.repo.create_tag(self.version)

    def __determine_bump(self):
        """Will go through the Git history until the last version bump
        and look for hints that we want to "automatically" bump
        our version"""
        self.repo = self.__load_git()
        vsn = None
        reg = re.compile(r'(\#|bump:|\[)(?P<bump>(patch|minor|major))(.*|\])',
                         re.MULTILINE)
        for commit in self.repo.iter_commits(self.options['branch']):
            # we go iterate back to the last time we bumped the version
            if commit.message.startswith('Version bumped to'):
                break

            res = reg.search(commit.message)
            if res:
                bump = res.group('bump')
                if not vsn:
                    vsn = bump
                elif vsn == 'patch' and bump == 'minor':
                    vsn = 'minor'
                elif vsn == 'patch' and bump == 'major':
                    vsn = 'major'
                elif vsn == 'minor' and bump == 'major':
                    vsn = 'major'
        return vsn

    def write_versionfile(self):
        """Write the version file"""
        path = os.path.join(self.directory, self.version_filename)
        version_file = open(path, 'w')
        version_file.write("%s\n" % self.version)
        version_file.close()

    def write_git(self):
        """Write data to git"""
        tag = None

        if not self.options['dry']:
            if not self._version.build:
                tag = self.__create_git_tag()
                self.__git_push(tag=tag)

    def bump(self, bump=None):
        """
        When using 'auto', flavor will attempt to determine whether or not
        the project needs to be bumped from git log history. If keywords are
        detected, project will update it's version to detected bump level and
        return True. If no keywords are detected, default_bump level will be
        used and True returned. If not, bump will return False.
        """
        if bump == 'auto':
            bump = self.__determine_bump()
            if bump is None and self.options['default_bump']:
                bump = self.options['default_bump']

        return super().bump(bump=bump)

    def read(self):
        git = Git(self.directory)
        out = git.tag(merged="HEAD", sort="-creatordate")
        tags = out.splitlines()
        tags = [t.strip(self.options['tag_prefix']) for t in tags]
        tags = sort_versions(tags)
        if len(tags) >= 2:
            latest_tag = tags[-1]
        elif len(tags) == 1:
            latest_tag = tags[0]
        else:
            raise AvakasError("No initial tag found!")

        self.version = latest_tag
        self.write_versionfile()

        return self.version

    def write(self):
        """
        Write version out to file
        """
        self.write_git()
        self.write_versionfile()
