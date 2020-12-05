"""
Avakas Utility Functions
"""

import re
import sys
import os
from functools import cmp_to_key
import contextlib

from semantic_version import compare


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


def match_and_rewrite_lines(pattern, file_body, version):
    """
    Replace lines by regex
    """
    lines = []
    updated = False
    for line in file_body.splitlines():
        re_out = re.sub(pattern, r'\1%s\3', line)
        if re_out != line:
            updated = True
            lines.append(re_out % version)
        else:
            lines.append(line)

    return ('\n'.join(lines), updated)


def sort_versions(versions):
    """
    Sort a list of version strings by semantic version
    """
    return sorted(versions, key=cmp_to_key(compare))
