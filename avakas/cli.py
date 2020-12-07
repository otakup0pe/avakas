"""avakas

The avakas tool is meant as an interface around version
metadata for assorted flavours of software projects.

For more information see https://github.com/otakup0pe/avakas
"""

from __future__ import print_function

import os
import sys
from datetime import datetime
import argparse

from git import Repo

from .avakas import detect_project_flavor
from .errors import AvakasError


def get_repo(directory):
    """Load the git repository."""
    return Repo(directory, search_parent_directories=True)


def git_rev(directory):
    """Returns the first eight characters of HEAD"""
    return str(get_repo(directory).head.commit)[0:8]


def add_metadata(project, **kwargs):
    """
    Add metadata for set/bump actions
    """
    directory = kwargs['directory'][0]

    git_str = str(git_rev(directory))
    if kwargs['buildmeta']:
        metadata = (git_str,)
        metadata += ci_build_meta()
        project.apply_metadata(*metadata)

    now = None
    if kwargs['prerelease_date']:
        time_fmt = "%Y%m%d%H%M%S"
        now = datetime.utcnow().strftime(time_fmt)

    if kwargs['prerelease']:
        project.make_prerelease(prefix=kwargs['prerelease_prefix'],
                                build_date=now)
    return project


def ci_build_meta():
    """Return any CI system specific build metadata"""
    meta = ()
    if 'BUILD_NUMBER' in os.environ:
        meta = (os.environ['BUILD_NUMBER'],)
    elif 'TRAVIS_BUILD_NUMBER' in os.environ:
        meta = (os.environ['TRAVIS_BUILD_NUMBER'],)
    elif 'CIRCLE_BUILD_NUM' in os.environ:
        meta = (os.environ['CIRCLE_BUILD_NUM'],)
    elif ('GITHUB_RUN_ID' in os.environ) and \
         ('GITHUB_RUN_NUMBER' in os.environ):
        meta = (os.environ['GITHUB_RUN_ID'], os.environ['GITHUB_RUN_NUMBER'],)
    return meta


def cli_show_version(**kwargs):
    """Show the current flavour specific version for a project."""
    project = detect_project_flavor(**kwargs)
    if not project.read():
        raise AvakasError('Unable to extract current version')

    print("%s" % str(project.version))


def cli_bump_version(**kwargs):
    """Bump the flavour specific version for a project."""
    project = detect_project_flavor(**kwargs)
    if not project.read():
        raise AvakasError('Unable to extract current version')
    old_version = project.version

    bump = kwargs['level'][0]

    if not project.bump(bump=bump):
        sys.exit(0)
    project = add_metadata(project, **kwargs)
    project.write()

    print("Version updated from %s to %s" %
          (old_version, str(project.version)))


def cli_set_version(**kwargs):
    """Manually set the flavour specific version for a project."""
    version = kwargs['version'][0]
    project = detect_project_flavor(**kwargs)

    project.version = version
    project = add_metadata(project, **kwargs)
    project.write()

    print("Version set to %s" % version)


def parse_args(parser):
    """Parse our command line arguments."""

    bump_levels = ['patch', 'minor', 'major', 'auto']

    parser = argparse.ArgumentParser(prog="avakas",
                                     description='Process some integers.')

    subparsers = parser.add_subparsers(dest='operation')

    common = argparse.ArgumentParser(add_help=False)
    common.add_argument('--tag-prefix', dest='tag_prefix',
                        help='Prefix for version tag name',
                        default='')

    common.add_argument('--branch', dest='branch',
                        help='Branch to use when updating git',
                        default='master')

    common.add_argument('--remote', dest='remote',
                        help='Git remote',
                        default='origin')

    common.add_argument('--filename', dest='filename',
                        help='File name. Used for fallback versioning.',
                        default='version')
    common.add_argument('--flavor', dest='flavor',
                        help='Automation flavor for the project',
                        default='auto')
    common.add_argument('directory', nargs=1,
                        help='Directory of the project', default=os.getcwd())

    writable = argparse.ArgumentParser(add_help=False)
    writable.add_argument('--build-meta', dest='buildmeta',
                          help='Apply build-meta to version',
                          action='store_true',
                          default=False)
    writable.add_argument('--skip-dirty', dest='skipdirty',
                          help='Skip checking if local repo is dirty',
                          action='store_true',
                          default=False)
    writable.add_argument('--skip-commit-changes', dest='commitchanges',
                          help='Skip commiting generated version files',
                          action='store_false',
                          default=True)
    writable.add_argument('--with-hooks', dest='with_hooks',
                          help='Run git hooks', default=False)
    writable.add_argument('--dry-run',
                          dest='dry',
                          help='Will not push to git',
                          action='store_true')
    writable.add_argument('--prerelease',
                          dest='prerelease',
                          help='Will include prebuild information. If '
                          ' no other prebuild options are specified '
                          ' then it will simply use the build info in place.',
                          action='store_true')
    writable.add_argument('--prerelease-date',
                          dest='prerelease_date',
                          help='Include a string representation of the '
                          'current date, down to the second, as part '
                          'of the prebuild.',
                          action='store_true')
    writable.add_argument('--prerelease-prefix',
                          dest='prerelease_prefix',
                          help='Use the given string as a prebuild prefix',
                          default=None)

    set_p = subparsers.add_parser('set', parents=[common, writable])
    set_p.add_argument('version', nargs=1,
                       help='Desired version to set')

    bump_p = subparsers.add_parser('bump', parents=[common, writable])
    bump_p.add_argument('level', nargs=1, choices=bump_levels,
                        help='Level to bump at', default='auto')
    bump_p.add_argument('--default-bump', dest='default_bump',
                        choices=bump_levels, help='Level to bump at',
                        default=None)

    subparsers.add_parser('show', parents=[common])

    return parser.parse_args()


def main():
    """Dat entrypoint"""
    parser = argparse.ArgumentParser(prog="avakas")
    args = parse_args(parser)

    if args.operation is None:
        parser.print_help()
        sys.exit(0)

    directory = os.path.abspath(args.directory[0])

    if not os.path.exists(directory):
        raise AvakasError("Directory %s does not exist." % directory)

    try:
        if args.operation == 'bump':
            cli_bump_version(**vars(args))
        elif args.operation == 'show':
            cli_show_version(**vars(args))
        elif args.operation == 'set':
            cli_set_version(**vars(args))
        else:
            parser.print_help()
    except AvakasError as err:
        print("Problem: %s" % err.message, file=sys.stderr)
        sys.exit(1)

    sys.exit(0)
