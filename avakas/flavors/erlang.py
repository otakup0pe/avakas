"""
Avakas Built-In Erlang/OTP Project Flavor
"""

import glob
import os
import re

from avakas.errors import AvakasError
from avakas.flavors.base import AvakasLegacy
from avakas.avakas import register_flavor


# Both patterns are needed: the literal one alone would silently skip a
# dynamic `{vsn, git}` or a second vsn tuple instead of refusing to guess.
VSN_TUPLE = re.compile(r'\{\s*vsn\s*,')
VSN_LITERAL = re.compile(r'(\{\s*vsn\s*,\s*")([^"]*)("\s*\})')


def _app_src_candidates(directory, filename=None):
    if filename and filename.endswith('.app.src'):
        return [os.path.join(directory, filename)]

    return sorted(glob.glob(os.path.join(directory, 'src', '*.app.src')))


def _read_app_src(path):
    with open(path, 'r', encoding='utf8') as handle:
        return handle.read()


def _mask_comments(content):
    """
    Blank every Erlang `%` comment with spaces. Offsets are preserved so a
    match found here can be spliced straight into the original bytes.
    """
    masked = []
    in_string = False
    escaped = False
    in_comment = False

    for char in content:
        if in_comment:
            in_comment = char != '\n'
            masked.append(char if char == '\n' else ' ')
        elif escaped:
            escaped = False
            masked.append(char)
        elif in_string and char == '\\':
            escaped = True
            masked.append(char)
        elif char == '"':
            in_string = not in_string
            masked.append(char)
        elif char == '%' and not in_string:
            in_comment = True
            masked.append(' ')
        else:
            masked.append(char)

    return ''.join(masked)


@register_flavor('erlang')
class AvakasErlangProject(AvakasLegacy):
    """
    Erlang/OTP src/<app>.app.src Avakas Project Flavor
    """
    PROJECT_TYPE = 'erlang'

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.app_src = self.__resolve_app_src()
        if self.app_src:
            self.version_filename = self.app_src
            self.commit_files = [self.app_src]

    @classmethod
    def guess_flavor(cls, directory):
        candidates = _app_src_candidates(directory)
        if len(candidates) != 1:
            return False

        masked = _mask_comments(_read_app_src(candidates[0]))
        if len(VSN_TUPLE.findall(masked)) != 1:
            return False

        return VSN_LITERAL.search(masked) is not None

    def __resolve_app_src(self):
        candidates = _app_src_candidates(self.directory,
                                         self.options.get('filename'))
        if len(candidates) > 1:
            names = ', '.join(os.path.basename(c) for c in candidates)
            raise AvakasError(
                f"Multiple application files found ({names}). Select one "
                "with --filename src/<app>.app.src"
            )

        if not candidates or not os.path.exists(candidates[0]):
            return None

        return os.path.relpath(candidates[0], self.directory)

    def __app_src_path(self):
        return os.path.join(self.directory, self.app_src)

    def __scan(self, content):
        """Return the one literal vsn match, refusing every other shape."""
        masked = _mask_comments(content)
        tuples = VSN_TUPLE.findall(masked)
        if not tuples:
            raise AvakasError(f"No vsn tuple in {self.app_src}")
        if len(tuples) > 1:
            raise AvakasError(f"Multiple vsn tuples in {self.app_src}")

        match = VSN_LITERAL.search(masked)
        if not match:
            raise AvakasError(
                f"The vsn in {self.app_src} is not a literal version"
            )

        return match

    def read(self):
        if not self.app_src:
            return False

        content = _read_app_src(self.__app_src_path())
        self.version = self.__scan(content).group(2)
        return True

    def write(self):
        if not self.app_src:
            raise AvakasError("No src/<app>.app.src file to write")

        self.check_if_dirty()
        path = self.__app_src_path()
        content = _read_app_src(path)
        match = self.__scan(content)
        updated = ''.join([
            content[:match.start()],
            match.group(1),
            str(self._version),
            match.group(3),
            content[match.end():],
        ])

        with open(path, 'w', encoding='utf8') as handle:
            handle.write(updated)

        self.commit_files = [self.app_src]
        self.write_git()
