avakas
======

This script provides a simple interface around viewing and manipulating project version metadata. It may be used to either bump, set, or view the version information for the project in a given directory. It is written with [semantic versioning](http://semver.org/) in mind.

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

# License

[MIT](https://github.com/otakup0pe/avakas/blob/master/LICENSE)

# Author

The avakas tool was created by Jonathan Freedman.
