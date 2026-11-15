"""Tests for the Erlang/OTP .app.src flavor."""

import tempfile
import unittest
from pathlib import Path

from avakas.avakas import detect_project_flavor
from avakas.errors import AvakasError
from avakas.flavors.erlang import AvakasErlangProject


APP_SRC = """{application, fixture, [
    {description, "Fixture application"},
    {vsn, "%s"},
    {registered, []},
    {applications, [kernel, stdlib]},
    {env, []},
    {modules, []}
]}.
"""


def write_app_src(directory, body, name="fixture"):
    """Write one src/<name>.app.src and return its path."""
    source = Path(directory, "src")
    source.mkdir(exist_ok=True)
    path = Path(source, f"{name}.app.src")
    path.write_text(body, encoding="utf8")
    return path


def erlang_project(directory, **kwargs):
    """Build the flavor directly, bypassing autodetection."""
    options = {
        "directory": [directory],
        "filename": "version",
        "tag_prefix": "",
        "flavor": "erlang",
    }
    options.update(kwargs)
    return detect_project_flavor(**options)


class ErlangDetectionTests(unittest.TestCase):
    """A single .app.src with a literal vsn selects the flavor."""

    def test_detects_erlang_project(self):
        with tempfile.TemporaryDirectory() as directory:
            write_app_src(directory, APP_SRC % "1.2.3")

            project = detect_project_flavor(
                directory=[directory],
                filename="version",
                tag_prefix="",
            )

        self.assertIsInstance(project, AvakasErlangProject)

    def test_ignores_dynamic_version(self):
        with tempfile.TemporaryDirectory() as directory:
            write_app_src(directory, APP_SRC % "1.2.3")
            path = Path(directory, "src", "fixture.app.src")
            path.write_text(
                path.read_text(encoding="utf8").replace('"1.2.3"', "git"),
                encoding="utf8",
            )

            self.assertFalse(
                AvakasErlangProject.guess_flavor(directory)
            )

    def test_ignores_multiple_application_files(self):
        with tempfile.TemporaryDirectory() as directory:
            write_app_src(directory, APP_SRC % "1.2.3", name="one")
            write_app_src(directory, APP_SRC % "1.2.3", name="two")

            self.assertFalse(
                AvakasErlangProject.guess_flavor(directory)
            )


class ErlangReadTests(unittest.TestCase):
    """Reading the vsn tuple is strict about what it accepts."""

    def test_reads_version(self):
        with tempfile.TemporaryDirectory() as directory:
            write_app_src(directory, APP_SRC % "1.2.3")
            project = erlang_project(directory)

            self.assertTrue(project.read())
            self.assertEqual(project.version, "1.2.3")

    def test_reads_version_with_odd_spacing(self):
        with tempfile.TemporaryDirectory() as directory:
            write_app_src(
                directory,
                '{application, fixture, [\n'
                '    %% {vsn, "0.0.0"} lived here once\n'
                '    {  vsn ,   "4.5.6"  }\n'
                ']}.\n',
            )
            project = erlang_project(directory)

            self.assertTrue(project.read())
            self.assertEqual(project.version, "4.5.6")

    def test_rejects_dynamic_version(self):
        with tempfile.TemporaryDirectory() as directory:
            write_app_src(
                directory,
                '{application, fixture, [\n    {vsn, git}\n]}.\n',
            )
            project = erlang_project(directory)

            with self.assertRaises(AvakasError) as caught:
                project.read()

        self.assertIn("not a literal version", str(caught.exception))

    def test_rejects_duplicate_version(self):
        with tempfile.TemporaryDirectory() as directory:
            write_app_src(
                directory,
                '{application, fixture, [\n'
                '    {vsn, "1.2.3"},\n'
                '    {vsn, "1.2.4"}\n'
                ']}.\n',
            )
            project = erlang_project(directory)

            with self.assertRaises(AvakasError) as caught:
                project.read()

        self.assertIn("Multiple vsn tuples", str(caught.exception))

    def test_read_is_false_without_an_application_file(self):
        with tempfile.TemporaryDirectory() as directory:
            project = erlang_project(directory)

            self.assertFalse(project.read())

    def test_rejects_ambiguous_application_files(self):
        with tempfile.TemporaryDirectory() as directory:
            write_app_src(directory, APP_SRC % "1.2.3", name="one")
            write_app_src(directory, APP_SRC % "1.2.3", name="two")

            with self.assertRaises(AvakasError) as caught:
                erlang_project(directory)

        self.assertIn("Multiple application files", str(caught.exception))

    def test_explicit_filename_selects_one_of_several(self):
        with tempfile.TemporaryDirectory() as directory:
            write_app_src(directory, APP_SRC % "1.2.3", name="one")
            write_app_src(directory, APP_SRC % "9.9.9", name="two")

            project = erlang_project(
                directory,
                filename="src/two.app.src",
            )

            self.assertTrue(project.read())
            self.assertEqual(project.version, "9.9.9")


if __name__ == "__main__":
    unittest.main()
