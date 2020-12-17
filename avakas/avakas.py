"""
Avakas classes and plugin handlers
"""

from semantic_version import Version

from .errors import AvakasError


def detect_project_flavor(**kwargs):
    """
    Determines the project flavor for a given directory
    """

    flavor = kwargs.get('flavor', 'auto')

    if flavor == 'auto':
        matched = [f for n, f
                   in Avakas.project_flavors.items()
                   if f.guess_flavor(directory=kwargs['directory'][0])]
        if len(matched) == 1:
            project = matched[0]
        elif len(matched) == 0:
            project = Avakas.project_flavors['legacy']
        else:
            matched_names = [f.PROJECT_TYPE for f in matched]
            raise AvakasError("Multiple project flavor matches: %s" %
                              ", ".join(matched_names))
    else:
        if flavor in Avakas.project_flavors:
            project = Avakas.project_flavors[flavor]
        else:
            raise AvakasError('Unable to find flavor "%s"' % flavor)

    return project(**kwargs)


class Avakas():
    """
    Main instance of Avakas associated to a project and it's version
    """
    project_flavors = {}

    def __init__(self, **kwargs):
        self._version = Version('0.0.0')
        self.directory = kwargs['directory'][0]
        self.options = kwargs

    @property
    def version(self):
        """Get version"""
        tag_prefix = self.options.get('tag_prefix', '')
        return "%s%s" % (tag_prefix, self._version)

    @version.setter
    def version(self, version):
        """Set version"""
        if not isinstance(version, str):
            raise TypeError("version must be type of str")

        tag_prefix = self.options.get('tag_prefix', None)
        version = version.strip(tag_prefix)

        try:
            self._version = Version(version)
        except ValueError as err:
            raise AvakasError("Invalid version string %s" %
                              version) from err

    @classmethod
    def read(cls):
        """Read version data from a project"""
        return True

    @classmethod
    def write(cls):
        """Write version data to a project"""

    def bump(self, bump=None):
        """Bump version"""
        if not bump:
            return False

        if bump == 'patch':
            self._version = self._version.next_patch()
        elif bump == 'minor':
            self._version = self._version.next_minor()
        elif bump == 'major':
            self._version = self._version.next_major()
        else:
            raise AvakasError("Invalid version component")

        return True

    def make_prerelease(self, prefix=None, build_date=None):
        """Make current version a prerelease"""
        release_pos = 1 if prefix else 0
        if self._version.prerelease:
            release = self._version.prerelease[release_pos]
        else:
            release = 1

        self.apply_prerelease((str(release)),
                              prefix=prefix,
                              build_date=build_date)

    def apply_metadata(self, *metadata):
        """Apply build metadata to project version"""
        self._version.build += metadata

    def apply_prerelease(self, *prebuild, prefix=None, build_date=None):
        """Apply prebuild data to project version"""
        if prefix:
            self._version.prerelease = (prefix,)

        self._version.prerelease += prebuild

        if build_date:
            self._version.prerelease += (build_date,)


def register_flavor(flavor):
    """
    Registers a Avakas Project Flavor
    Used for future language/project expansions
    """
    def wrapper(project):
        Avakas.project_flavors[flavor] = project
        return project
    return wrapper
