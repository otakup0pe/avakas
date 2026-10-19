"""Tests for release-intent marker parsing and flavor registration."""

import unittest

from avakas import Avakas
from avakas.bump_markers import find_bumps, highest_bump


class BumpMarkerTests(unittest.TestCase):
    """Release intent is explicit, bounded, and case-insensitive."""

    def test_accepts_supported_markers(self):
        cases = {
            "#patch": "patch",
            "Fix a bug\n#MINOR": "minor",
            "bump:major": "major",
            "bump: patch": "patch",
            "BUMP:\tMinor": "minor",
            "[major]": "major",
            "[ patch ]": "patch",
        }

        for message, expected in cases.items():
            with self.subTest(message=message):
                self.assertEqual({expected}, find_bumps(message))

    def test_rejects_marker_lookalikes(self):
        messages = (
            "[patches applied]",
            "[minor changes only]",
            "#patchwork",
            "bump:majority",
            "embump:patch",
        )

        for message in messages:
            with self.subTest(message=message):
                self.assertEqual(set(), find_bumps(message))

    def test_selects_highest_marker_across_messages(self):
        messages = (
            "first\n#patch",
            "second\nbump: minor",
            "third\n[major]",
        )

        self.assertEqual("major", highest_bump(messages))

    def test_no_marker_has_no_bump(self):
        self.assertIsNone(highest_bump(("docs only", "still docs")))


class FlavorRegistrationTests(unittest.TestCase):
    """The new name and compatibility alias select the same flavor."""

    def test_git_tag_is_canonical_git_native_alias(self):
        git_tag = Avakas.project_flavors["git-tag"]
        git_native = Avakas.project_flavors["git-native"]

        self.assertIs(git_tag, git_native)
        self.assertEqual("git-tag", git_tag.PROJECT_TYPE)


if __name__ == "__main__":
    unittest.main()
