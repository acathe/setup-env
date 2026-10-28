import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
PYTHON_INSTALLER = ROOT / "debian/code/python.sh"
OMZ_INSTALLER = ROOT / "debian/command/omz/update.sh"
UPDATES = ROOT / "debian/command/omz/plugins/update-all-in-one/custom"
COMMAND_STUB = """import json
import os
from pathlib import Path
import sys

command = Path(sys.argv[0]).name
with open(os.environ["CALL_LOG"], "a") as log:
    log.write(json.dumps([command, *sys.argv[1:]]) + "\\n")
if command == "uv" and sys.argv[1:2] == ["python"]:
    sys.exit(int(os.environ.get("UV_PYTHON_STATUS", "0")))
"""


class UvScriptsTest(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix="setup-env-uv-test-")
        self.addCleanup(temporary.cleanup)
        self.directory = Path(temporary.name)
        binaries = self.directory / "bin"
        binaries.mkdir()
        for command in ("brew", "uv", "curl"):
            stub = binaries / command
            stub.write_text(f"#!{sys.executable}\n{COMMAND_STUB}")
            stub.chmod(0o755)
        self.log = self.directory / "calls.jsonl"
        self.env = {
            **os.environ,
            "PATH": f"{binaries}{os.pathsep}{os.defpath}",
            "HOME": str(self.directory / "home"),
            "CALL_LOG": str(self.log),
            "UV_PYTHON_STATUS": "0",
            "ZSH_CUSTOM": str(self.directory / "custom"),
            "CODE_PYTHON": "1",
            "CODE_RUST": "0",
            "COMMAND_MODERN_CLI": "0",
            "APP_YAZI": "0",
        }

    def run_script(self, shell, script):
        command = [shutil.which(shell)]
        if shell == "zsh":
            command.append("-f")
        return subprocess.run(
            [*command, str(script)],
            env=self.env,
            capture_output=True,
            text=True,
            check=False,
        )

    def uv_calls(self):
        calls = [json.loads(line) for line in self.log.read_text().splitlines()]
        return [call[1:] for call in calls if call[0] == "uv"]

    def update_fragment(self):
        fragments = list(UPDATES.glob("03-*.zsh"))
        self.assertEqual(len(fragments), 1)
        return fragments[0]

    def test_installs_python_before_tools(self):
        result = self.run_script("bash", PYTHON_INSTALLER)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            self.uv_calls(),
            [["python", "install", "-q"], ["tool", "install", "-q", "py-spy"]],
        )

    def test_python_install_failure_does_not_install_tools(self):
        self.env["UV_PYTHON_STATUS"] = "23"
        result = self.run_script("bash", PYTHON_INSTALLER)
        self.assertEqual(result.returncode, 23, result.stderr)
        self.assertEqual(self.uv_calls(), [["python", "install", "-q"]])

    def test_updates_python_before_tools(self):
        result = self.run_script("zsh", self.update_fragment())
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            self.uv_calls(),
            [["python", "upgrade", "-q"], ["tool", "upgrade", "-q", "--all"]],
        )

    def test_python_upgrade_failure_does_not_upgrade_tools(self):
        self.env["UV_PYTHON_STATUS"] = "23"
        result = self.run_script("zsh", self.update_fragment())
        self.assertEqual(result.returncode, 23, result.stderr)
        self.assertEqual(self.uv_calls(), [["python", "upgrade", "-q"]])

    def test_installs_renamed_update_fragment(self):
        result = self.run_script("bash", OMZ_INSTALLER)
        self.assertEqual(result.returncode, 0, result.stderr)
        installed = Path(self.env["ZSH_CUSTOM"]) / "plugins/update-all-in-one/custom"
        self.assertTrue((installed / "03-uv.zsh").is_file())
        self.assertFalse((installed / "03-uv-tools.zsh").exists())


if __name__ == "__main__":
    unittest.main()
