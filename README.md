avakas
======

[![PyPI](https://img.shields.io/pypi/v/avakas.svg)](https://pypi.python.org/pypi/avakas)[![Maintenance](https://img.shields.io/maintenance/yes/2020.svg)]()


# Overview

This script provides a simple interface around viewing and manipulating project version metadata. It may be used to either bump, set, or view the version information for the project in a given directory. It is written with [semantic versioning](http://semver.org/) in mind.

It currently does it's best to determine whether the given directory contains a NodeJS, Erlang, Chef Cookbook, or Ansible project before just settling on keeping the version in a file named `version`. If a NodeJS project is discovered then the `package.json` will be edited. If an Ansible project is discovered then no files will be modified but the tags will still be handled. The Erlang detection is limited to OTP apps, and `avakas` will attempt to edit a rebar style `foo.app.src`. If a Chef Cookbook is discovered then `avakas` will attempt to modify the `version` attribute in `metadata.rb`.

The avakas tool makes a few assumptions

* There is only one logical project in each directory.

The avakas tool supports the following types of version files

* NodeJS `package.json`
* Erlang/OTP and rebar `foo.app.src`
* Chef Cookbook `metadata.rb`
* Ansible `meta/main.yml`
* Plain ol' `version` file


# Operations

## show

This mode will return the current version for a given project. Some optional arguments include:

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
* `pre` will update the prerelease (to the right, separated by a `-`)
* `auto` will attempt to determine which component to adjust

### Autobump

When the `auto` option is selected, the system will use hints in the git log since the last version bump to determine if the version should be changed. These hints can be specified at any point in the commit message. The hints are specified, prefixed by `bump:`. For example, the following commit message would result in a minor version bump if it is subsequently "autobumped".

```shell
$ avakas show .
0.0.1
$ git commit -am "hello this is a release\nbump:minor"
$ avakas bump . auto
Version updated from 0.0.1 to 0.1.0
```

Avakas can also rely on a default bump version to ensure every invocation of Avakas generates a bump build. If a bump hint is not detected within the commit history, the defined defualt-bump level will be used. This is useful for CI/CD systems.

```shell
avakas bump . auto --default-bump patch
```


# Arguments

## --tag-prefix

A prefix to use with the version. Generally used for non-semantic version compliant v1.0 style version strings.

## --branch

The authoritative mainline branch of your project. This is also used to compare for prereleases.

## --remote

The git remote origin to push changes to.

## --filename

The filename to use for generating a version file.

## --flavor

Flavor of project (Presently: legacy|chef|ansible|nodejs|erlang).

## --build-meta

Whether to apply semantic version compliant build metadata to the version. (Example: `1.0.0+4c5fa2.1`)

## --skip-dirty

Skip checking if local repo is dirty.

## --skip-commit-changes

Skip committing generated version files.

## --with-hooks

Run git hooks during operations.

## --dry-run

Will not push to git.

## --prerelease

Will attempt to generate a prerelease version. (Example: `1.0.0-1`)

## --prerelease-date

Will attach the data to the prerelease identifiers. (Example: `1.0.0-1.20201220`)

## --prerelease-prefix

Will use a prefix for the prerelease. (Example: `1.0.0-alpha.1`)


# Docker

You can use `avakas` as a Docker container as well. It supports either static SSH keys or the SSH Agent. It seems like the SSH agent only works on Linux though. The Docker entrypoint should setup your SSH environment on the `set` and `bump` `avakas` actions.

You can map a folder to `/etc/avakas` for static SSH or Git environment configuration. If the file `avakasrc` is present in `/etc/avakas` it will be sourced prior to running `avakas`. A common use case here is to export the `GIT_AUTHOR_NAME` and `GIT_AUTHOR_EMAIL` environment variables.

In all cases, you will want to map a source project into a folder and point `avakas` at it. The following example (running on Linux with SSH Agent forwarding) would bump the patch portion of the version in the current directory.

```
$ docker run -t -v $(pwd):/app -v $SSH_AUTH_SOCK:/ssh-agent -e SSH_AUTH_SOCK=/ssh-agent otakup0pe/avakas bump /app patch
```

The next example (running on OSX) would set the version explicitly in the current directory. Note how we need to setup a working folder to map `/etc/avakas` against.

```
$ mkdir -p /tmp/ssh-avakas-working
$ cp ~/.ssh/id_rsa /tmp/ssh-avakas-working
$ docker run  -v $(pwd):/app -v /tmp/ssh-avakas-working:/etc/avakas otakup0pe/avakas set /app 0.0.1
```


# License

[MIT](https://github.com/otakup0pe/avakas/blob/master/LICENSE)


# Author

The avakas tool was created by [Jonathan Freedman](http://jonathanfreedman.bio/).
