import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
OMZ = ROOT / "debian/command/omz"
RUFF_URL = (
    "https://raw.githubusercontent.com/BesLogic/"
    "Beslogic-Ruff-Config/refs/heads/main/ruff.toml"
)


class PythonUpdaterTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(dir=os.environ.get("TMPDIR"))
        self.addCleanup(temporary.cleanup)
        self.directory = Path(temporary.name)
        self.home = self.directory / "test home"
        self.custom = self.home / "omz custom"
        self.updaters = self.custom / "plugins/update-all-in-one/custom"
        self.updaters.mkdir(parents=True)
        self.environment = {
            "PATH": "/usr/bin:/bin",
            "HOME": str(self.home),
            "ZSH_CUSTOM": str(self.custom),
            "CODE_PYTHON": "1",
            "COMMAND_MODERN_CLI": "0",
            "CODE_RUST": "0",
            "APP_YAZI": "0",
            "LC_ALL": "C",
        }

    def install_updates(self, python="1"):
        result = subprocess.run(
            ["bash", "--noprofile", "--norc", str(OMZ / "update.sh")],
            env={**self.environment, "CODE_PYTHON": python},
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)

    def run_updates(self):
        self.install_updates()
        for name in ("00-apt.zsh", "01-homebrew.zsh", "99-oh-my-zsh.zsh"):
            (self.updaters / name).unlink()

        binaries = self.directory / "bin"
        binaries.mkdir()
        trace = self.directory / "commands.jsonl"
        command_double = f"""#!{sys.executable} -I
import json
import os
from pathlib import Path
import sys

command = Path(sys.argv[0]).name
arguments = sys.argv[1:]
with open(os.environ["TEST_TRACE"], "a") as stream:
    stream.write(json.dumps([command, *arguments]) + "\\n")
if command == "curl":
    destination = Path(os.environ["HOME"]) / ".config/ruff/ruff.toml"
    if arguments != ["-fsSL", {RUFF_URL!r}, "-o", str(destination)]:
        sys.exit("Unexpected Ruff download arguments")
    destination.write_text("line-length = 100\\n")
"""
        for command in ("uv", "curl"):
            executable = binaries / command
            executable.write_text(command_double)
            executable.chmod(0o755)

        result = subprocess.run(
            [
                "zsh", "-f", "-c", 'source "$1"; update-all-in-one',
                "test-updater",
                str(OMZ / "plugins/update-all-in-one/update-all-in-one.plugin.zsh"),
            ],
            cwd=self.directory,
            env={
                **self.environment,
                "PATH": f"{binaries}:/usr/bin:/bin",
                "TEST_TRACE": str(trace),
            },
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        return [json.loads(line) for line in trace.read_text().splitlines()]

    def test_installation_replaces_legacy_python_updater(self):
        legacy = self.updaters / "03-uv.zsh"
        legacy.write_text("uv python upgrade -q && uv tool upgrade -q --all\n")
        unrelated = self.updaters / "98-manual.zsh"
        unrelated.write_text("# Keep user update scripts\n")

        self.install_updates()

        self.assertTrue((self.updaters / "03-python.zsh").is_file())
        self.assertFalse(legacy.exists())
        self.assertEqual(unrelated.read_text(), "# Keep user update scripts\n")

    def test_installation_without_python_preserves_legacy_updater(self):
        legacy = self.updaters / "03-uv.zsh"
        legacy.write_text("# Existing updater\n")

        self.install_updates(python="0")

        self.assertEqual(legacy.read_text(), "# Existing updater\n")
        self.assertFalse((self.updaters / "03-python.zsh").exists())

    def test_updates_overwrite_existing_ruff_fallback(self):
        fallback = self.home / ".config/ruff/ruff.toml"
        fallback.parent.mkdir(parents=True)
        fallback.write_text("line-length = 88\n")

        commands = self.run_updates()

        self.assertEqual(fallback.read_text(), "line-length = 100\n")
        self.assertEqual(commands, [
            ["uv", "python", "upgrade", "-q"],
            ["uv", "tool", "upgrade", "-q", "--all"],
            ["curl", "-fsSL", RUFF_URL, "-o", str(fallback)],
        ])
        self.assertEqual(list(fallback.parent.iterdir()), [fallback])

    def test_updates_create_missing_ruff_directory(self):
        fallback = self.home / ".config/ruff/ruff.toml"

        self.run_updates()

        self.assertTrue(fallback.is_file(), "Ruff fallback was not downloaded")
        self.assertEqual(fallback.read_text(), "line-length = 100\n")


if __name__ == "__main__":
    unittest.main()
