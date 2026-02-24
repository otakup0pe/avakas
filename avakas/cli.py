"""Avakas: A tool for managing semantic versioning in software projects.

Avakas provides a command-line interface to manage version numbers in various
types of software projects (known as "flavors").
"""

from __future__ import print_function

import os
import sys
import argparse

from git import Repo

from .avakas import detect_project_flavor, Avakas
from .errors import AvakasError
from .utils import my_version


def get_repo(directory):
    """Load the git repository from a given directory.

            Args:
                directory (str): The path to the project directory. The
                    function will search this directory and its parents for
                    a git repository.

            Returns:
                git.Repo: The loaded git repository object.
            """
    return Repo(directory, search_parent_directories=True)


def git_rev(directory):
    """Get the short commit hash of the current HEAD.

            Args:
                directory (str): The path to the directory containing the git
                    repository.

            Returns:
                str: The first eight characters of the HEAD commit hash.
            """
    return str(get_repo(directory).head.commit)[0:8]


def add_metadata(project, buildmeta=False, **kwargs):
    """Add build metadata to the project's version.

            This function adds the git commit hash and, optionally, CI build
            information to the version string.

            Args:
                project (Avakas): The Avakas project instance.
                buildmeta (bool): If True, add CI build metadata.
                **kwargs: Additional arguments, including
                          the project directory.

            Returns:
                Avakas: The modified project instance.
            """
    directory = kwargs['directory'][0]

    git_str = str(git_rev(directory))
    if buildmeta:
        metadata = (git_str,)
        metadata += ci_build_meta()
        project.apply_metadata(*metadata)

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

    if kwargs['prerelease']:
        project.make_prerelease(0,
                                kwargs['prerelease_prefix'],
                                kwargs['prerelease_date'])

    mod_version = project.version_obj
    if kwargs['prerelease'] and kwargs['strip_prerelease']:
        raise AvakasError('cannot specify prerelease and strip-prerelease')

    if kwargs['strip_prerelease']:
        mod_version.prerelease = None

    if kwargs['strip_build']:
        mod_version.build = None

    project.version = mod_version
    print(str(project.version))


def cli_bump_version(
        level=None,
        prerelease=False,
        prerelease_date=False, **kwargs):
    """Bump the flavour specific version for a project."""
    project = detect_project_flavor(**kwargs)
    if not project.read():
        raise AvakasError('Unable to extract current version')
    old_version = project.version

    if not project.bump(
            bump=level[0],
            prerelease=prerelease,
            prerelease_prefix=kwargs['prerelease_prefix'],
            build_date=prerelease_date):
        sys.exit(0)
    project = add_metadata(project, **kwargs)
    project.write()

    print(f"Version updated from {old_version} to {str(project.version)}")


def cli_set_version(prerelease=False,
                    prerelease_date=False,
                    prerelease_prefix=None,
                    **kwargs):
    """Manually set the flavour specific version for a project."""

    version = kwargs['version'][0]
    project = detect_project_flavor(**kwargs)
    original_version = project.version_obj

    project.version = version
    if prerelease:
        prerelease_version = project.get_next_prerelease_version(
            starting_version=original_version,
            prefix=prerelease_prefix,
            new_version=project.version_obj
        )
        project.make_prerelease(prerelease_version, build_date=prerelease_date)
    project = add_metadata(project, **kwargs)
    project.write()

    print(f"Version set to {project.version}")


def gen_arg_parser():
    """Generate parser for command line arguments."""

    argparse.ArgumentParser(prog="avakas")
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
                        default='mainline')

    common.add_argument('--remote', dest='remote',
                        help='Git remote',
                        default='origin')

    common.add_argument('--filename', dest='filename',
                        help='File name. Used for fallback versioning.',
                        default='version')
    flavor_text = 'Automation flavor for the project (%s)'
    flavors = []
    for flavor, _class in Avakas.project_flavors.items():
        flavors.append(flavor)

    common.add_argument('--flavor', dest='flavor',
                        help=flavor_text % ','.join(flavors),
                        default='auto')
    common.add_argument('directory', nargs=1,
                        help='Directory of the project', default=os.getcwd())

    writable = argparse.ArgumentParser(add_help=False)
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

    meta = argparse.ArgumentParser(add_help=False)
    meta.add_argument('--prerelease',
                      dest='prerelease',
                      help='Will include pre-release information. If '
                      ' no other pre-release options are specified '
                      ' then it will simply use the build info in place.',
                      action='store_true')
    meta.add_argument('--prerelease-date',
                      dest='prerelease_date',
                      help='Include a string representation of the '
                      'current date, down to the second, as part '
                      'of the pre-release.',
                      action='store_true')
    meta.add_argument('--prerelease-prefix',
                      dest='prerelease_prefix',
                      help='Use the given string as a pre-release prefix',
                      default=None)
    meta.add_argument('--build-meta', dest='buildmeta',
                      help='Apply build-meta to version',
                      action='store_true',
                      default=False)

    set_p = subparsers.add_parser('set',
                                  parents=[common, writable, meta],
                                  help='explicitly set new version')
    set_p.add_argument('version', nargs=1,
                       help='Desired version to set')

    bump_p = subparsers.add_parser('bump',
                                   parents=[common, writable, meta],
                                   help='bump version')
    bump_p.add_argument('level', nargs=1, choices=bump_levels,
                        help='Level to bump at', default='auto')
    bump_p.add_argument('--default-bump', dest='default_bump',
                        choices=bump_levels, help='Level to bump at',
                        default=None)

    show_p = subparsers.add_parser('show',
                                   parents=[common, meta],
                                   help='show current project version')
    show_p.add_argument('--strip-prerelease',
                        help='Do not include prerelease information',
                        action='store_true',
                        default=False)
    show_p.add_argument('--strip-build',
                        help='Do not include build information',
                        action='store_true',
                        default=False)

    subparsers.add_parser('version')
    subparsers.add_parser('help')

    return parser


def main():
    """Dat entrypoint"""
    parser = gen_arg_parser()
    args = parser.parse_args()

    if args.operation is None:
        parser.print_help()
        sys.exit(1)

    if args.operation == 'version':
        print(f"avakas v{my_version()}")
        sys.exit(0)
    elif args.operation == 'help':
        parser.print_help()
        sys.exit(0)

    directory = os.path.abspath(args.directory[0])

    if not os.path.exists(directory):
        raise AvakasError(f"Directory {directory} does not exist.")

    try:
        if args.operation == 'bump':
            cli_bump_version(**vars(args))
        elif args.operation == 'show':
            cli_show_version(**vars(args))
        elif args.operation == 'set':
            cli_set_version(**vars(args))
        else:
            parser.print_help()
            sys.exit(1)
    except AvakasError as err:
        print(f"Problem: {err.message}", file=sys.stderr)
        sys.exit(1)

    sys.exit(0)
