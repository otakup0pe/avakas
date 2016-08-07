avakas
======

[![Build Status](https://travis-ci.org/otakup0pe/avakas.svg?branch=master)](https://travis-ci.org/otakup0pe/avakas)[![PyPI](https://img.shields.io/pypi/v/avakas.svg)](https://pypi.python.org/pypi/avakas)[![Maintenance](https://img.shields.io/maintenance/yes/2016.svg)]()

# Overview

This script provides a simple interface around viewing and manipulating project version metadata. It may be used to either bump, set, or view the version information for the project in a given directory. It is written with [semantic versioning](http://semver.org/) in mind.

It currently does it's best to determine whether the given directory contains a NodeJS, Erlang, Chef Cookbook, or Ansible project before just settling on keeping the version in a file named `version`. If a NodeJS project is discovered then the `package.json` will be edited. If an Ansible project is discovered then no files will be modified but the tags will still be handled. The Erlang detection is limited to OTP apps, and `avakas` will attempt to edit a rebar style `foo.app.src`. If a Chef Cookbook is discovered then `avakas` will attempt to modify the `version` attribute in `metadata.rb`.

The avakas tool makes a few assumptions

* There is only one logical project in each directory.
* The directory is somewhere in a git repository. You can have multiple projects per repository by using the `--tag-prefix` option.
* For the protection of the user the git workspace must not be dirty.

The avakas tool supports the following types of version files

* NodeJS `package.json`
* Erlang/OTP and rebar `foo.app.src`
* Chef Cookbook `metadata.rb`
* Plain ol' `version` file

# Operations

## show

This mode will return the current version for a given project. The following will show the current Public API version. This operation supports an additional `--build` argument, which will cause it to extend the version set in source control with build-time metadata. It also supports the `--pre-build` argument, which does the same thing on top of the prerelease field, because all kinds of package management systems do not actually support the build semantic version component.


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
* `pre` will update the prerelase (to the right, separated by a `-`)

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

The avakas tool was created by [Jonathan Freedman](http://jonathanfreedman.bio/).
