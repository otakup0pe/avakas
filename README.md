avakas
======

# Overview

This script provides a simple interface around viewing and manipulating project version metadata. It may be used to either bump, set, or view the version information for the project in a given directory. It is written with [semantic versioning](http://semver.org/) in mind.

It currently does it's best to determine whether the given directory contains a NodeJS or Ansible package before just settling on a keeping the version in a file named `version`. If a NodeJS project is discovered then the `package.json` will be edited. If an Ansible project is discovered then no files will be modified.

The avakas tool makes a few assumptions

* There is only one logical project in each directory.
* The directory is somewhere in a git repository. You can have multiple projects per repository by using the `--tag-prefix` option.
* For the protection of the user the git workspace must not be dirty.

# Operations

## show

This mode will return the current version for a given project. The following will show the current Public API version.

```shell
avakas show $HOME/projects/hal9000
```

## set

This mode will set an explicit version. Note that the string must be a valid semantic version.
```shell
avakas set $HOME/projects/hal9000 2.0.0
```

## bump

This mode will automatically update the version based on the input provided. It has four modes of operation.

* `major` will update the major (left) version component.
* `minor` will update the minor (middle) version component.
* `patch` will update the patch (right) version component.
* `dev` will keep the core version but set the build version based on a combination of GIT revision, and jenkins/local build number.

# Arguments

### `--dry-run`

This will result in nothing being pushed to upstream git sources.

### `--branch`

The branch to use when updating git.

### `--remote`

The remote to push tags and version updates.

### `--tag-prefix`

This prefix will be added to the version string when creating a git tag.

# License

[MIT](https://github.com/otakup0pe/avakas/blob/master/LICENSE)

# Author

The avakas tool was created by Jonathan Freedman.

# Disclaimer

Consider this software as alpha. It's worth mentioning that I've broken git repositories a few times with pygit. I'll remove this disclaimer once I'm a little more comfortable with those interactions.
