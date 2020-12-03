"""
Avakas classes and plugin handlers
"""

import sys
import os

from semantic_version import Version

from .errors import AvakasError


def detect_project_flavor(**kwargs):
    """
    Determines the project flavor for a given directory
    """

    matched = [f for n, f
               in Avakas.project_flavors.items()
               if f(**kwargs).guess_flavor()]

    if len(matched) == 1:
        project = matched[0](**kwargs)
    elif len(matched) == 0:
        project = Avakas.project_flavors['default'](**kwargs)
    else:
        matched_names = [f.PROJECT_TYPE for f in matched]
        print("Multiple project flavor matches: %s" %
              ", ".join(matched_names))
        sys.exit(1)

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
        if isinstance(self.version, Version):
            raise TypeError("Must be type str")
        return self.version

    def set_version(self, version):
        """Set version"""
        if isinstance(self.version, Version):
            raise TypeError("Must be type str")
        self.version = Version(version)

    def bump(self, bump):
        """Bump version"""
        new_version = None
        old_version = Version(self.version)
        if bump == 'patch':
            new_version = old_version.next_patch()
        elif bump == 'minor':
            new_version = old_version.next_minor()
        elif bump == 'major':
            new_version = old_version.next_major()
        elif bump == 'pre':
            new_version = old_version
            prereleases = len(new_version.prerelease)
            if prereleases == 1:
                new_version.prerelease = (str(
                                          int(new_version.prerelease[0]) + 1))
            elif prereleases == 0:
                new_version.prerelease = ('1')
            else:
                new_version = AvakasError("Unexpected version prerelease")

        else:
            new_version = AvakasError("Invalid version component")

        return new_version


def register_flavor(flavor):
    """
    Registers a Avakas Project Flavor
    Used for future language/project expansions
    """
    def wrapper(project):
        Avakas.project_flavors[flavor] = project
        return project
    return wrapper
