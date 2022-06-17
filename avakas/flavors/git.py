"""
Avakas Built-In Base Project Flavor
"""

import os
import re

from git import Repo

import semantic_version

from avakas.errors import AvakasError
from avakas.avakas import Avakas, register_flavor

PATCH = 'patch'
MAJOR = 'major'
MINOR = 'minor'

# not gonna convert everything to be an enum just yet -TMJ
BUMPS = {
    PATCH: 0,
    MINOR: 1,
    MAJOR: 2
}


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

    def __init__(self, filename, tag_prefix='v', **kwargs):
        # not sure if setting tag_prefix to ! None is too prescriptive
        super().__init__(**kwargs)
        self.tag_prefix = tag_prefix
        self.version_filename = filename
        self.repo = self.__load_git()

    def __load_git(self):
        """Initializes our local git workspace."""
        repo = Repo(self.directory, search_parent_directories=True)
        if not repo:
            raise AvakasError("Unable to find associated git repo for %s." %
                              self.directory)

        return repo

    def _version_from_tag(self, tag):
        try:
            return semantic_version.Version(tag.name[len(self.tag_prefix):])
        except ValueError:
            return None

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

    def _get_extant_prerelease_versions(
            self, prefix, base_version=None, extant_versions=None):
        """
        Get all tags in this repo, use them to determine all of the pre-
        releases for this version, with this pre-release prefix, which have
        previously existed

        ## Note:
           This does not fetch tags from remotes
        """
        if extant_versions is None:
            extant_versions = set()

        tag_versions = [self._version_from_tag(t) for t in self.repo.tags]
        extant_versions.update(v for v in tag_versions if v is not None)
        return super()._get_extant_prerelease_versions(
            prefix=prefix,
            base_version=base_version,
            extant_versions=extant_versions)

    def __determine_bump(self, for_prerelease=False):
        """Will go through the Git history until the last version bump
        and look for hints that we want to "automatically" bump
        our version"""
        self.repo = self.__load_git()
        vsn = None
        reg = re.compile(r'(\#|bump:|\[)(?P<bump>(patch|minor|major))(.*|\])',
                         re.MULTILINE)
        tagged_commits = {}
        for tag in self.repo.tags:
            tagged_commits.setdefault(tag.commit, set()).add(tag)

        # the most recent tag, whether pre-release or no
        tag_version = None
        release_version = None
        bump = None
        head_commit = self.repo.heads[self.options['branch']].commit

        for commit in self.repo.iter_commits(self.options['branch']):
            # we go iterate back to the last time we bumped the version
            if commit in tagged_commits:
                version_tags = [self._version_from_tag(tag) for tag in
                                tagged_commits[commit]]

                version_tags = [tag for tag in version_tags if tag is not None]

                release_tags = [tag for tag in version_tags if
                                not tag.prerelease]

                if any(release_tags):
                    release_version = max(release_tags)
                if any(version_tags) and tag_version is None:
                    tag_version = max(version_tags)

                    if for_prerelease and commit == head_commit:
                        return bump

            if release_version is not None:
                break  # break out of for commit iterator

            res = reg.search(commit.message)
            if res:
                bump = res.group('bump')
                if not vsn:
                    vsn = bump
                else:
                    vsn = max((vsn, bump), key=lambda x: BUMPS[x])

            if release_version is not None:
                break
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

    def bump(self,
             bump=None,
             prerelease=False,
             prerelease_prefix=None, build_date=None):
        """
        When using 'auto', flavor will attempt to determine whether or not
        the project needs to be bumped from git log history. If keywords are
        detected, project will update it's version to detected bump level and
        return True. If no keywords are detected, default_bump level will be
        used and True returned. If not, bump will return False.
        """
        if bump == 'auto':
            bump = self.__determine_bump(for_prerelease=prerelease)
            if bump is None and self.options['default_bump']:
                bump = self.options['default_bump']

        return super().bump(
            bump=bump,
            prerelease=prerelease,
            prerelease_prefix=prerelease_prefix,
            build_date=build_date)

    def read(self):
        latest_tag = None
        commit_to_tags = {}
        for tag in self.repo.tags:
            commit_to_tags.setdefault(tag.commit, set()).add(tag)

        for commit in self.repo.iter_commits(self.options['branch']):
            if commit in commit_to_tags:
                version_tags = [self._version_from_tag(tag) for tag in
                                commit_to_tags[commit]]

                version_tags = [tag for tag in version_tags if tag is not None]
                if version_tags:
                    latest_tag = max(version_tags)
            if latest_tag is not None:
                break

        if latest_tag is None:
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
