"""
Avakas Built-In Base Project Flavor
"""

import os

from git import Repo
from git.remote import PushInfo

import semantic_version

from avakas.errors import AvakasError
from avakas.avakas import Avakas, register_flavor
from avakas.bump_markers import highest_bump


PUSH_FAILURES = (
    PushInfo.ERROR
    | PushInfo.REJECTED
    | PushInfo.REMOTE_REJECTED
    | PushInfo.REMOTE_FAILURE
)


@register_flavor('git-native')
@register_flavor('git-tag')
class AvakasGitNative(Avakas):
    """
    Avakas Git Native - using tags only
    Similar to thorscmversion
    """
    PROJECT_TYPE = 'git-tag'

    @classmethod
    def guess_flavor(cls, directory):
        """
        Always return false as this is an explicitly called
        flavor.
        """
        # pylint: disable=unused-argument
        return False

    def __init__(self, filename, tag_prefix='v', **kwargs):
        super().__init__(**kwargs)
        self.tag_prefix = tag_prefix
        self.version_filename = filename
        self.repo = self.__load_git()

    def __load_git(self):
        """Initializes our local git workspace."""
        repo = Repo(self.directory, search_parent_directories=True)
        if not repo:
            raise AvakasError(f"Unable to find associated git \
            repo for {self.directory}")

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

        resp = None
        if tag:
            remote = self.repo.remote(name=opt['remote'])
            resp = remote.push(tag)[0]

        if resp.flags & PUSH_FAILURES:
            raise AvakasError(f"Unexpected git error: {resp.summary}")

    def __create_git_tag(self):
        """Creates a git tag"""
        return self.repo.create_tag(self.version)

    def _get_extant_prerelease_versions(
            self, prefix, base_version, extant_versions=None):
        """Include prerelease tags from every branch in allocation."""
        versions = set(extant_versions or ())
        versions.update(
            version
            for version in (
                self._version_from_tag(tag) for tag in self.repo.tags
            )
            if version is not None
        )
        return super()._get_extant_prerelease_versions(
            prefix=prefix,
            base_version=base_version,
            extant_versions=versions,
        )

    def __determine_bump(self, for_prerelease=False):
        """Will go through the Git history until the last version bump
        and look for hints that we want to "automatically" bump
        our version"""
        self.repo = self.__load_git()
        tagged_commits = {}
        for tag in self.repo.tags:
            tagged_commits.setdefault(tag.commit, set()).add(tag)

        messages = []
        head_commit = self.repo.head.commit

        for commit in self.repo.iter_commits("HEAD"):
            if commit in tagged_commits:
                version_tags = [
                    self._version_from_tag(tag)
                    for tag in tagged_commits[commit]
                ]
                version_tags = [
                    tag for tag in version_tags if tag is not None
                ]
                release_tags = [
                    tag for tag in version_tags if not tag.prerelease
                ]

                if release_tags:
                    break
                if version_tags and for_prerelease and commit == head_commit:
                    return None

            messages.append(commit.message)

        return highest_bump(messages)

    def write_versionfile(self):
        """Write the version file"""
        path = os.path.join(self.directory, self.version_filename)
        with open(path, 'w', encoding='utf8') as version_file:
            version_file.write(f"{self.version}\n")
            version_file.close()

    def write_git(self):
        """Write data to git"""
        tag = None

        if not self.options['dry']:
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
        """
        Get the version from git tag
        """
        latest_tag = None
        commit_to_tags = {}
        for tag in self.repo.tags:
            commit_to_tags.setdefault(tag.commit, set()).add(tag)

        for commit in self.repo.iter_commits("HEAD"):
            if commit in commit_to_tags:
                version_tags = [self._version_from_tag(tag) for tag in
                                commit_to_tags[commit]]

                version_tags = [tag for tag in version_tags if tag is not None]
                if version_tags:
                    latest_tag = max(version_tags)
            if latest_tag is not None:
                break

        if latest_tag is None:
            return False

        self.version = latest_tag
        return self.version

    def write(self):
        """
        Write version out to file
        """
        self.write_git()
