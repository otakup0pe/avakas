"""
Avakas Built-In Base Project Flavor
"""

import os
import re
import sys

from git import Repo

from avakas.errors import AvakasError
from avakas.avakas import Avakas, register_flavor
from avakas.utils import stdout_redirect


@register_flavor('legacy')
class AvakasLegacy(Avakas):
    """
    Default Legacy Avakas Project Flavor
    """
    PROJECT_TYPE = 'legacy'

    @classmethod
    def guess_flavor(cls, directory):
        """
        Return true if determined this is the project's flavor.
        For example, current directory has a meta/version file,
        return a true value.
        """
        os.path.exists(directory)
        # For legacy, this should _ALWAYS_ return False
        return False

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.repo = None
        self.version_filename = kwargs['filename']
        self.commit_files = [self.version_filename]

    def __load_git(self):
        """Initializes our local git workspace."""
        opt = self.options
        repo = Repo(self.directory, search_parent_directories=True)
        if not repo:
            raise AvakasError("Unable to find associated git repo for %s." %
                              self.directory)

        if opt['branch'] not in repo.heads:
            raise AvakasError("Branch %s branch not found." % opt['branch'])

        if repo.active_branch != repo.heads[opt['branch']]:
            print("Switching to %s branch" % opt['branch'],
                  file=sys.stderr)
            repo.heads[opt['branch']].checkout()

        if opt['remote'] not in [r.name for r in repo.remotes]:
            raise AvakasError("Remote %s not found" % opt['remote'])

        # we really do not want to be polluting our stdout when
        # showing the version
        with stdout_redirect():
            repo.remotes[opt['remote']].pull(refspec=opt['branch'])

        return repo

    def __git_push(self, tag=None):
        """Push git commit or tag to remote"""
        opt = self.options
        if tag:
            resp = self.repo.remotes[opt['remote']].push(tag)

        resp = self.repo.remotes[opt['remote']].push()
        resp = resp[0]
        if resp.flags & 1024 or resp.flags & 32 or resp.flags & 16:
            raise AvakasError("Unexpected git error: %s" % resp.summary)

    def __commit_files(self):
        """Will commit and push the version file and optionally tags."""
        opt = self.options

        self.repo.index.add(self.commit_files)
        skip_hooks = not opt['with_hooks']
        self.repo.index.commit("Version bumped to %s" % self.version,
                               skip_hooks=skip_hooks)

    def __create_git_tag(self):
        """Creates a git tag"""
        tag = self.version
        self.repo.create_tag(tag)

        return tag

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

    def check_if_dirty(self):
        """Check if the repo is dirty"""
        self.repo = self.__load_git()
        if not self.options['skipdirty'] and self.repo.is_dirty():
            raise AvakasError("Git repo dirty.")

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
            if self.version_filename and self.options['commitchanges']:
                self.__commit_files()
                self.__git_push()

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
        """
        Get the version from the current project flavor
        """
        path = os.path.join(self.directory, self.version_filename)
        version_file = open(path, 'r')
        version_str = version_file.read()
        self.version = version_str
        version_file.close()
        return True

    def write(self):
        """
        Write version out to file
        """

        self.check_if_dirty()
        self.write_versionfile()
        self.write_git()
