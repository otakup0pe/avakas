"""
Avakas classes and plugin handlers
"""

import os

from semantic_version import Version

from .errors import AvakasError


def detect_project_flavor(**kwargs):
    """
    Determines the project flavor for a given directory
    """
    options = kwargs.get('opt', {})
    flavor = options.get('flavor', 'auto')

    if flavor == 'auto':
        matched = [f for n, f
                   in Avakas.project_flavors.items()
                   if f(**kwargs).guess_flavor()]

        if len(matched) == 1:
            project = matched[0](**kwargs)
        elif len(matched) == 0:
            project = Avakas.project_flavors['legacy'](**kwargs)
        else:
            matched_names = [f.PROJECT_TYPE for f in matched]
            raise AvakasError("Multiple project flavor matches: %s" %
                              ", ".join(matched_names))
    else:
        if flavor in Avakas.project_flavors:
            project = Avakas.project_flavors[flavor](**kwargs)
        else:
            raise AvakasError('Unable to find flavor "%s"' % flavor)

    return project


class Avakas():
    """
    Main instance of Avakas associated to a project and it's version
    """
    project_flavors = {}

    def __init__(self, **kwargs):
        self.version = Version('0.0.0')
        self.directory = kwargs.get('directory', os.getcwd())

    def get_version(self):
        """Get version"""
        return str(self.version)

    def set_version(self, version):
        """Set version"""
        if isinstance(version, str):
            self.version = Version(version)
        else:
            self.version = version

    def bump(self, bump):
        """Bump version"""
        old_version = self.version
        if bump == 'patch':
            self.version = old_version.next_patch()
        elif bump == 'minor':
            self.version = old_version.next_minor()
        elif bump == 'major':
            self.version = old_version.next_major()
        else:
            raise AvakasError("Invalid version component")

    def make_prerelease(self, prefix=None, build_date=None):
        """Make current version a prerelease"""
        release_pos = 1 if prefix else 0
        if self.version.prerelease:
            release = self.version.prerelease[release_pos]
        else:
            release = 1

        self.apply_prerelease((str(release)),
                              prefix=prefix,
                              build_date=build_date)

    def apply_metadata(self, *metadata):
        """Apply build metadata to project version"""
        self.version.build += metadata

    def apply_prerelease(self, *prebuild, prefix=None, build_date=None):
        """Apply prebuild data to project version"""
        if prefix:
            self.version.prerelease += (prefix,)

        self.version.prerelease += prebuild

        if build_date:
            self.version.prerelease += (build_date,)


def register_flavor(flavor):
    """
    Registers a Avakas Project Flavor
    Used for future language/project expansions
    """
    def wrapper(project):
        Avakas.project_flavors[flavor] = project
        return project
    return wrapper
