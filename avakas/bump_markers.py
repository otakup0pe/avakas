"""Parse semantic-version bump markers from commit messages."""

import re


BUMP_PRIORITY = {
    "patch": 0,
    "minor": 1,
    "major": 2,
}

_MARKER_RE = re.compile(
    r"""
    (?:
        (?<!\w)\#(?P<hash>patch|minor|major)\b
        |
        (?<!\w)bump:[ \t]*(?P<label>patch|minor|major)\b
        |
        \[[ \t]*(?P<bracket>patch|minor|major)[ \t]*\]
    )
    """,
    re.IGNORECASE | re.VERBOSE,
)


def find_bumps(message):
    """Return the distinct bump levels explicitly marked in a message."""
    bumps = set()
    for match in _MARKER_RE.finditer(message):
        bump = next(group for group in match.groups() if group is not None)
        bumps.add(bump.lower())
    return bumps


def highest_bump(messages):
    """Return the highest bump level found across commit messages."""
    bumps = (
        bump
        for message in messages
        for bump in find_bumps(message)
    )
    return max(bumps, key=BUMP_PRIORITY.get, default=None)
