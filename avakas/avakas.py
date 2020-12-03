"""
Avakas classes and plugin handlers
"""

import sys
import os

from semantic_version import Version


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
    Main instance of Avakas
    """
    project_flavors = {}

    def __init__(self, **kwargs):
        self.version = Version('0.0.0')
        self.directory = kwargs.get('directory', os.getcwd())

    def get_version(self):
        """Get version"""
        if isinstance(self.version, str):
            version = Version(self.version)
        else:
            version = self.version
        return version

    def set_version(self, version):
        """Set version"""
        self.version = Version(version)


def register_flavor(flavor):
    """
    Registers a Avakas Project Flavor
    Used for future language/project expansions
    """
    def wrapper(project):
        Avakas.project_flavors[flavor] = project
        return project
    return wrapper
