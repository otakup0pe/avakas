"""Tests for automatic project-flavor detection."""

import json
import tempfile
import unittest
from pathlib import Path

from avakas.avakas import detect_project_flavor
from avakas.flavors.node import AvakasNodeProject


class FlavorDetectionTests(unittest.TestCase):
    """Project manifests select their matching flavor."""

    def test_detects_node_project(self):
        with tempfile.TemporaryDirectory() as directory:
            manifest = Path(directory, "package.json")
            manifest.write_text(
                json.dumps({"name": "fixture", "version": "1.2.3"}),
                encoding="utf8",
            )

            project = detect_project_flavor(
                directory=[directory],
                filename="version",
                tag_prefix="",
            )

        self.assertIsInstance(project, AvakasNodeProject)


if __name__ == "__main__":
    unittest.main()
