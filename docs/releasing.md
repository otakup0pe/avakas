# Releasing Avakas

Avakas releases itself after changes reach `mainline`. The build workflow
installs Avakas from the checked-out commit, determines release intent from
commit messages, updates `pyproject.toml`, and creates the version commit,
tag, and GitHub Release. The release workflow then publishes the Python package
to PyPI and the container image to Docker Hub.

## Declare release intent

Include one of these markers in a commit message:

- `#patch`, `#minor`, or `#major`;
- `bump:patch`, `bump: minor`, or `bump:major`;
- `[patch]`, `[minor]`, or `[major]`.

Markers are case-insensitive. If several commits request different levels, the
highest level wins. A merge with no marker does not create a release.

Before merging, update `CHANGELOG.md` for the intended version and confirm
that every required pull-request check passes.

## Automated release flow

After a marked change reaches `mainline`, `build.yml`:

1. runs the Python, container, package, and secret-scanning gates;
2. installs Avakas from that exact checkout;
3. runs `avakas bump . auto --branch=mainline --flavor pep621`;
4. pushes the `Version bumped to <version>` commit and matching tag;
5. creates the GitHub Release for that tag.

The generated version commit runs the gates again but is excluded from another
bump. Creating the GitHub Release starts `release.yml`, which publishes the
distribution and the versioned and `latest` container tags.

PyPI versions and release tags are immutable. Never reuse a published version
or move an existing release tag.

## Required secrets

- `DEPLOY_KEY`: an SSH key allowed to push the version commit and tag;
- `RELEASE_TOKEN`: a GitHub token allowed to create the release and trigger
  the downstream release workflow;
- `PYPI_TOKEN`: a PyPI API token authorized for the `avakas` project;
- `DOCKER_TOKEN`: a Docker Hub token for the repository owner.

## Verify and recover

Confirm both workflows completed, the version is visible on PyPI, and both
Docker tags resolve to the new image. A failed release workflow may be rerun:
PyPI publication skips an already-uploaded file, and Docker tags are safe to
replace with the same release build.

If the version is wrong, publish a new patch release. Do not rewrite the
existing version commit, tag, release, or package.
