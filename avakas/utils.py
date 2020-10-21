"""
Avakas Utility Functions
"""

import re


def match_and_rewrite_lines(pattern, file_body, version):
    """
    Replace lines by regex
    """
    lines = []
    updated = False
    for line in file_body:
        re_out = re.sub(pattern, r'\1%s\3', line)
        if re_out != line:
            updated = True
            lines.append(re_out % version)
        else:
            lines.append(line)

    return (lines, updated)
