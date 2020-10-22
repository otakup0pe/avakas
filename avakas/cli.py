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
from optparse import OptionParser
import contextlib

from semantic_version import Version

from git import Repo

from .avakas import Avakas


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


def problems(msg):
    """Simple give-up and error out function."""
    print("Problem: %s" % msg,
          file=sys.stderr)
    sys.exit(1)


def git_push(repo, opt, tag=None):
    """Pushes the repository to our remote."""
    if tag:
        info = repo.remotes[opt.remote].push(tag)
    else:
        info = repo.remotes[opt.remote].push()
    info = info[0]
    if info.flags & 1024 or info.flags & 32 or info.flags & 16:
        problems("Unexpected git error: %s" % info.summary)


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

    ava = Avakas(directory=directory, opt=opt.__dict__)
    project = ava.flavor

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
        problems("Unable to find associated git repo for %s." % directory)

    if not opt.skipdirty and repo.is_dirty():
        problems("Git repo dirty.")

    if opt.branch not in repo.heads:
        problems("Branch %s branch not found." % opt.branch)

    if repo.active_branch != repo.heads[opt.branch]:
        print("Switching to %s branch" % opt.branch,
              file=sys.stderr)
        repo.heads[opt.branch].checkout()
    else:
        print("Already on %s branch" % opt.branch,
              file=sys.stderr)

    if opt.remote not in [r.name for r in repo.remotes]:
        problems("Remote %s not found" % opt.remote)

    # we really do not want to be polluting our stdout when showing the version
    with stdout_redirect():
        repo.remotes[opt.remote].pull(refspec=opt.branch)

    return repo


def transmogrify_version(version, bump):
    """Update the version string."""
    new_version = None
    if bump == 'patch':
        new_version = version.next_patch()
    elif bump == 'minor':
        new_version = version.next_minor()
    elif bump == 'major':
        new_version = version.next_major()
    elif bump == 'pre':
        new_version = Version(str(version))
        prereleases = len(new_version.prerelease)
        if prereleases == 1:
            new_version.prerelease = (str(int(new_version.prerelease[0]) + 1))
        elif prereleases == 0:
            new_version.prerelease = ('1')
        else:
            problems("Unexpected version prerelease")

    else:
        problems("Invalid version component")

    return new_version


def get_repo(directory):
    """Load the git repository."""
    return Repo(directory, search_parent_directories=True)


def git_rev(directory):
    """Returns the first eight characters of HEAD"""
    return str(get_repo(directory).head.commit)[0:8]


def bump_auto(artifact_version, repo, opt):
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

    if not vsn:
        print("No auto bump indicators", file=sys.stderr)
        sys.exit(0)

    return transmogrify_version(artifact_version, vsn)


def bump_version(repo, directory, bump, opt):
    """Bump the flavour specific version for a project."""
    ava = Avakas(directory=directory, opt=opt.__dict__)
    project = ava.flavor
    artifact_version = Version(project.get_version())

    if bump == 'auto':
        new_version = bump_auto(artifact_version, repo, opt)
    else:
        new_version = transmogrify_version(artifact_version, bump)

    project.set_version(new_version)

    print("Version updated from %s to %s" % (artifact_version, new_version))
    return new_version


def set_version(directory, version, opt):
    """Manually set the flavour specific version for a project."""
    try:
        version = Version(version)
    except ValueError:
        problems("Invalid version string %s" % version)

    ava = Avakas(directory=directory, opt=opt.__dict__)
    project = ava.flavor
    project.set_version(version)

    print("Version set to %s" % version)


def ci_build_meta():
    """Return any CI system specific build metadata"""
    ci_version = None
    if 'BUILD_NUMBER' in os.environ:
        ci_version = os.environ['BUILD_NUMBER']
    elif 'TRAVIS_BUILD_NUMBER' in os.environ:
        ci_version = os.environ['TRAVIS_BUILD_NUMBER']
    elif 'CIRCLE_BUILD_NUM' in os.environ:
        ci_version = os.environ['CIRCLE_BUILD_NUM']
    elif ('GITHUB_RUN_ID' in os.environ) and \
         ('GITHUB_RUN_NUMBER' in os.environ):
        ci_version = "%s.%s" % (os.environ['GITHUB_RUN_ID'],
                                os.environ['GITHUB_RUN_NUMBER'])

    return ci_version


def prebuild_meta():
    """Generate pre-build metadata"""
    time_fmt = "%Y%m%d%H%M%S"
    now_str = datetime.utcnow().strftime(time_fmt)
    return now_str


def append_prebuild_version(opt, git_str, artifact_version):
    """Append the prebuild version component if so desired."""
    if not (opt.prebuild_prefix or opt.prebuild_date):
        if artifact_version.prerelease:
            artifact_version.prerelease = artifact_version.prerelease \
                                          + (git_str,)
        else:
            artifact_version.prerelease = (git_str,)

        ci_version = ci_build_meta()
        if ci_version:
            artifact_version.prerelease = artifact_version.prerelease \
                                          + (ci_version,)
    else:
        if opt.prebuild_prefix:
            artifact_version.prerelease = artifact_version.prerelease \
                                          + (opt.prebuild_prefix,)

        if opt.prebuild_date:
            artifact_version.prerelease = artifact_version.prerelease \
                                          + (prebuild_meta(),)


def append_build_version(git_str, artifact_version):
    """Append the build version component if so desired."""
    if artifact_version.build:
        artifact_version.build = artifact_version.build \
                                 + (git_str,)
    else:
        artifact_version.build = (git_str,)

    ci_version = ci_build_meta()
    if ci_version:
        artifact_version.build = artifact_version.build \
                                 + (ci_version,)


def show_version(directory, opt):
    """Show the current flavour specific version for a project."""
    ava = Avakas(directory=directory, opt=opt.__dict__)
    project = ava.flavor
    artifact_version = Version(project.get_version())

    if not artifact_version:
        problems('Unable to extract current version')

    git_str = str(git_rev(directory))
    if opt.build:
        append_build_version(git_str, artifact_version)
    if opt.prebuild:
        append_prebuild_version(opt, git_str, artifact_version)

    print("%s" % str(artifact_version))


def parse_args(parser):
    """Parse our command line arguments."""

    operation = sys.argv[1]

    parser.add_option('--tag-prefix',
                      dest='tag_prefix',
                      help='Prefix for version tag name',
                      default=None)
    parser.add_option('--branch',
                      dest='branch',
                      help='Branch to use when updating git',
                      default='master')
    parser.add_option('--remote',
                      dest='remote',
                      help='Git remote',
                      default='origin')
    parser.add_option('--filename',
                      dest='filename',
                      help='File name. Used for fallback versioning.',
                      default='version')
    parser.add_option('--skip-dirty',
                      dest='skipdirty',
                      help='Skip checking if local repo is dirty',
                      action='store_true',
                      default=False)
    parser.add_option('--skip-commit-changes',
                      dest='commitchanges',
                      help='Skip commiting generated version files',
                      action='store_false',
                      default=True)

    if operation in ('set', 'bump'):
        parser.add_option('--with-hooks',
                          dest='with_hooks',
                          help='Run git hooks',
                          default=False)

    if operation == 'show':
        parser.add_option('--build',
                          dest='build',
                          help='Will include build information '
                          'in build semver component',
                          action='store_true')
        parser.add_option('--pre-build',
                          dest='prebuild',
                          help='Will include prebuild information. If '
                          ' no other prebuild options are specified '
                          ' then it will simply use the build info in place.',
                          action='store_true')
        parser.add_option('--pre-build-date',
                          dest='prebuild_date',
                          help='Include a string representation of the '
                          'current date, down to the second, as part '
                          'of the prebuild.',
                          action='store_true')
        parser.add_option('--pre-build-prefix',
                          dest='prebuild_prefix',
                          help='Use the given string as a prebuild prefix')
    else:
        parser.add_option('--dry-run',
                          dest='dry',
                          help='Will not push to git',
                          action='store_true')

    (opt, args) = parser.parse_args()
    if operation == 'help':
        usage(parser)
        sys.exit(0)
    else:
        if len(args) < 2:
            usage(parser)
            sys.exit(1)

    return (operation, opt, args)


def main():
    """Dat entrypoint"""
    if len(sys.argv) < 2:
        usage()
        sys.exit(1)

    parser = OptionParser()
    (operation, opt, args) = parse_args(parser)

    directory = os.path.abspath(args[1])

    if not os.path.exists(directory):
        problems("Directory %s does not exist." % directory)

    if operation == 'bump':
        bump = 'dev'
        if len(args) >= 3:
            bump = args[2].lower()
            if bump in ('patch', 'minor', 'major', 'pre', 'auto'):
                repo = load_git(directory, opt)
                version = bump_version(repo, directory, bump, opt)
                write_git(repo, directory, version, opt)
                sys.exit(0)
    elif operation == 'show':
        if opt.build and opt.prebuild and not \
           (opt.prebuild_prefix or opt.prebuild_date):
            problems('Cannot specify --build with empty --prebuild')
        show_version(directory, opt)
        sys.exit(0)
    elif operation == 'set':
        if len(args) == 3:
            repo = load_git(directory, opt)
            version = args[2]
            set_version(directory, version, opt)
            write_git(repo, directory, version, opt)
            sys.exit(0)

    usage(parser)
    sys.exit(1)
