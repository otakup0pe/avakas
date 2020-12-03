"""avakas

The avakas tool is meant as an interface around version
metadata for assorted flavours of software projects.

For more information see https://github.com/otakup0pe/avakas
"""

from __future__ import print_function

import os
import re
import sys
from datetime import datetime
import argparse
import contextlib

from semantic_version import Version

from git import Repo

from .avakas import detect_project_flavor
from .errors import AvakasError


@contextlib.contextmanager
def stdout_redirect():
    """ Forcefully redirect stdout to stderr """
    # http://marc-abramowitz.com/archives/2013/07/19/python-context-manager-for-redirected-stdout-and-stderr/
    try:
        oldstdchannel = os.dup(sys.stdout.fileno())
        os.dup2(sys.stderr.fileno(), sys.stdout.fileno())

        yield
    finally:
        if oldstdchannel is not None:
            os.dup2(oldstdchannel, sys.stdout.fileno())


def usage(parser=None):
    """Display usage syntax."""
    print("avakas show <directory>")
    print("avakas bump <directory> [pre|patch|minor|major]")
    print("avakas set <directory> <version>")
    if parser:
        parser.print_help()


def git_push(repo, opt, tag=None):
    """Pushes the repository to our remote."""
    if tag:
        info = repo.remotes[opt.remote].push(tag)
    else:
        info = repo.remotes[opt.remote].push()
    info = info[0]
    if info.flags & 1024 or info.flags & 32 or info.flags & 16:
        raise AvakasError("Unexpected git error: %s" % info.summary)


def write_git(repo, directory, vsn_str, opt):
    """Will commit and push the version file and optionally tags."""
    if isinstance(vsn_str, str):
        version = Version(vsn_str)
    else:
        version = vsn_str
        vsn_str = str(version)

    if opt.tag_prefix:
        tag = "%s%s" % (opt.tag_prefix, vsn_str)
    else:
        tag = vsn_str

    if opt.dry:
        print("Would have pushed %s to %s." % (vsn_str, opt.remote),
              file=sys.stderr)
        if not version.build:
            print("Would have tagged as %s." % tag,
                  file=sys.stderr)

        return

    project = detect_project_flavor(directory=directory, opt=opt.__dict__)

    if project.version_filename and opt.commitchanges:
        repo.index.add([project.version_filename])
        skip_hooks = True
        if opt.with_hooks:
            skip_hooks = False

        repo.index.commit("Version bumped to %s" % vsn_str,
                          skip_hooks=skip_hooks)
        git_push(repo, opt)

    if not version.build:
        repo.create_tag(tag)
        git_push(repo, opt, tag)


def load_git(directory, opt):
    """Initializes our local git workspace."""
    repo = get_repo(directory)
    if not repo:
        raise AvakasError("Unable to find associated git repo for %s." %
                          directory)

    if not opt.skipdirty and repo.is_dirty():
        raise AvakasError("Git repo dirty.")

    if opt.branch not in repo.heads:
        raise AvakasError("Branch %s branch not found." % opt.branch)

    if repo.active_branch != repo.heads[opt.branch]:
        print("Switching to %s branch" % opt.branch,
              file=sys.stderr)
        repo.heads[opt.branch].checkout()
    else:
        print("Already on %s branch" % opt.branch,
              file=sys.stderr)

    if opt.remote not in [r.name for r in repo.remotes]:
        raise AvakasError("Remote %s not found" % opt.remote)

    # we really do not want to be polluting our stdout when showing the version
    with stdout_redirect():
        repo.remotes[opt.remote].pull(refspec=opt.branch)

    return repo


def get_repo(directory):
    """Load the git repository."""
    return Repo(directory, search_parent_directories=True)


def git_rev(directory):
    """Returns the first eight characters of HEAD"""
    return str(get_repo(directory).head.commit)[0:8]


def determine_bump(repo, opt):
    """Will go through the Git history until the last version bump
    and look for hints that we want to "automatically" bump
    our version"""
    vsn = None
    reg = re.compile(r'bump:(?P<bump>(patch|minor|major)).*', re.MULTILINE)
    for commit in repo.iter_commits(opt.branch):
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


def cli_bump_version(directory, opt):
    """Bump the flavour specific version for a project."""
    repo = load_git(directory, opt)
    project = detect_project_flavor(directory=directory, opt=opt.__dict__)
    artifact_version = project.get_version()

    bump = opt.level[0]

    if bump == 'auto':
        bump = determine_bump(repo, opt)
        if not bump:
            print("No auto bump indicators", file=sys.stderr)
            sys.exit(0)

    new_version = project.bump(bump)
    project.set_version(new_version)

    write_git(repo, directory, new_version, opt)

    print("Version updated from %s to %s" % (artifact_version, new_version))


def cli_set_version(directory, opt):
    """Manually set the flavour specific version for a project."""
    version = opt.version[0]
    repo = load_git(directory, opt)
    try:
        Version(version)
    except ValueError as err:
        raise AvakasError("Invalid version string %s" % version) from err

    project = detect_project_flavor(directory=directory, opt=opt.__dict__)
    project.set_version(version)

    write_git(repo, directory, version, opt)

    print("Version set to %s" % version)


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


def cli_show_version(directory, opt):
    """Show the current flavour specific version for a project."""
    if opt.build and opt.prebuild and not \
       (opt.prebuild_prefix or opt.prebuild_date):
        raise AvakasError('Cannot specify build without prebuild')

    project = detect_project_flavor(directory=directory, opt=opt.__dict__)
    artifact_version = project.get_version()

    if not artifact_version:
        raise AvakasError('Unable to extract current version')

    now = None
    if opt.prebuild_date:
        time_fmt = "%Y%m%d%H%M%S"
        now = datetime.utcnow().strftime(time_fmt)

    git_str = str(git_rev(directory))
    if opt.build:
        metadata = (git_str,)
        metadata += ci_build_meta()
        project.apply_metadata(*metadata)
    if opt.prebuild:
        prebuild = (git_str,)
        prebuild += ci_build_meta()
        project.apply_prebuild(*prebuild,
                               prefix=opt.prebuild_prefix,
                               prebuild_date=now)

    print("%s" % str(project.version))


def parse_args(parser):
    """Parse our command line arguments."""

    bump_levels = ['pre', 'patch', 'minor', 'major', 'auto']

    parser = argparse.ArgumentParser(prog="avakas",
                                     description='Process some integers.')

    subparsers = parser.add_subparsers(dest='operation')

    common = argparse.ArgumentParser(add_help=False)
    common.add_argument('--tag-prefix', dest='tag_prefix',
                        help='Prefix for version tag name',
                        default=None)

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
                        help='Directory of the project', default='.')

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

    set_p = subparsers.add_parser('set', parents=[common, writable])
    set_p.add_argument('version', nargs=1,
                       help='Desired version to set')

    bump_p = subparsers.add_parser('bump', parents=[common, writable])
    bump_p.add_argument('level', nargs=1, choices=bump_levels,
                        help='Level to bump at', default='auto')

    show_p = subparsers.add_parser('show', parents=[common])
    show_p.add_argument('--build',
                        dest='build',
                        help='Will include build information '
                        'in build semver component',
                        action='store_true')
    show_p.add_argument('--pre-build',
                        dest='prebuild',
                        help='Will include prebuild information. If '
                        ' no other prebuild options are specified '
                        ' then it will simply use the build info in place.',
                        action='store_true')
    show_p.add_argument('--pre-build-date',
                        dest='prebuild_date',
                        help='Include a string representation of the '
                        'current date, down to the second, as part '
                        'of the prebuild.',
                        action='store_true')
    show_p.add_argument('--pre-build-prefix',
                        dest='prebuild_prefix',
                        help='Use the given string as a prebuild prefix',
                        default=None)

    return parser.parse_args()


def main():
    """Dat entrypoint"""
    parser = argparse.ArgumentParser(prog="avakas")
    args = parse_args(parser)

    directory = os.path.abspath(args.directory[0])

    if not os.path.exists(directory):
        raise AvakasError("Directory %s does not exist." % directory)

    try:
        if args.operation == 'bump':
            cli_bump_version(directory, args)
        elif args.operation == 'show':
            cli_show_version(directory, args)
        elif args.operation == 'set':
            cli_set_version(directory, args)
    except AvakasError as err:
        print("Problem: %s" % err.message, file=sys.stderr)
        sys.exit(1)

    sys.exit(0)
