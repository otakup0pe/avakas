"""
Avakas Utility Functions
"""

import re
from functools import cmp_to_key

from semantic_version import compare


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
