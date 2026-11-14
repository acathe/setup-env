"""Behavioral regressions for the development-container cleanup."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[1]


class SetupCleanupTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(
            prefix="setup-cleanup-", dir=os.environ.get("TMPDIR")
        )
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.home = self.root / "home"
        self.custom = self.home / ".oh-my-zsh" / "custom"
        self.bin = self.root / "bin"
        self.tmp = self.root / "tmp"
        for directory in (self.custom, self.bin, self.tmp):
            directory.mkdir(parents=True)

        # Only real, local commands needed by the scripts are reachable via PATH.
        for name in ("bash", "dirname", "install"):
            executable = shutil.which(name, path=os.defpath)
            if executable is None:
                self.fail(f"Required local command missing: {name}")
            (self.bin / name).symlink_to(executable)
        self.zsh = shutil.which("zsh", path=os.defpath)
        if self.zsh is None:
            self.fail("These shell integration tests require zsh")

        # Never inherit personal startup files, language exports or installer flags.
        self.environment = {
            "PATH": str(self.bin),
            "HOME": str(self.home),
            "ZDOTDIR": str(self.home),
            "ZSH_CUSTOM": str(self.custom),
            "TMPDIR": str(self.tmp),
            "LC_ALL": "C",
            "TERM": "dumb",
            "TERM_PROGRAM": "test-terminal",
            "COMMAND_MODERN_CLI": "0",
            "CODE_GO": "0",
            "CODE_PROTOBUF": "0",
            "CODE_PYTHON": "0",
            "CODE_RUST": "0",
            "APP_DOCKER": "0",
            "APP_GIT": "0",
            "APP_VSCODE": "0",
            "APP_YAZI": "0",
        }

    def run_script(self, arguments, **environment):
        result = subprocess.run(
            [str(argument) for argument in arguments],
            cwd=self.root,
            env={**self.environment, **environment},
            capture_output=True,
            text=True,
            timeout=10,
        )
        self.assertEqual(
            result.returncode,
            0,
            f"Script failed with status {result.returncode}: {result.stderr}",
        )
        self.assertEqual(result.stderr, "", "Unexpected shell diagnostics")
        return result.stdout

    def container_dispatcher(self):
        container = self.root / "container"
        container.mkdir()
        dispatcher = container / "main.sh"
        shutil.copyfile(REPO / "container" / "main.sh", dispatcher)

        # Replace only the service boundary, never the real argument parser.
        # Distinct service IDs make selecting the wrong entry point observable.
        for service in ("copilot-api", "dev-container"):
            entry = container / service / "main.sh"
            entry.parent.mkdir()
            entry.write_text(
                "#!/usr/bin/env bash\n"
                "set -euo pipefail\n"
                f"printf '%s\\0' '{service}' \"$@\"\n",
                encoding="utf-8",
            )
        return dispatcher

    def install_custom(self, **environment):
        self.run_script(
            [
                self.bin / "bash",
                "--noprofile",
                "--norc",
                REPO / "debian" / "command" / "omz" / "custom.sh",
            ],
            **environment,
        )

    def deployed_environment(self, fragment, **environment):
        # A removed language fragment should yield a clean new shell. Never
        # source the whole custom directory: it contains plugins and gh login.
        output = self.run_script(
            [
                self.zsh,
                "-d",
                "-f",
                "-c",
                'set -eu\n'
                'if [[ -f "$1" ]]; then\n'
                '    source "$1"\n'
                'fi\n'
                'exec "$2" -I -B -c "$3"\n',
                "setup-cleanup",
                self.custom / fragment,
                sys.executable,
                "import json, os; print(json.dumps(dict(os.environ)))",
            ],
            **environment,
        )
        return json.loads(output)

    def test_default_dispatches_to_copilot_api(self):
        """Catch the no-argument path still selecting the retired service."""
        output = self.run_script(
            [self.bin / "bash", "--noprofile", "--norc", self.container_dispatcher()]
        )
        self.assertEqual(output, "copilot-api\0")

    def test_explicit_copilot_image_preserves_remaining_arguments(self):
        """Catch lost CLI precedence, reordered args, or split/expanded values."""
        output = self.run_script(
            [
                self.bin / "bash",
                "--noprofile",
                "--norc",
                self.container_dispatcher(),
                "--auth",
                "--image",
                "copilot-api",
                "--add-api-key",
                "key with spaces",
                "",
                "--unknown",
                "$HOME",
                "--port",
                "4141",
            ],
            IMAGE="dev-container",
        )
        self.assertEqual(
            output.split("\0"),
            [
                "copilot-api",
                "--auth",
                "--add-api-key",
                "key with spaces",
                "",
                "--unknown",
                "$HOME",
                "--port",
                "4141",
                "",
            ],
        )

    def test_rust_setup_does_not_export_container_workaround(self):
        """Catch CODE_RUST deploying a fragment that still exports the workaround."""
        self.install_custom(CODE_RUST="1")
        environment = self.deployed_environment("16-rust.zsh")
        self.assertNotIn("RUSTUP_PERMIT_COPY_RENAME", environment)

    def test_python_setup_does_not_export_container_workaround(self):
        """Catch CODE_PYTHON deploying a fragment that still forces uv copy mode."""
        self.install_custom(CODE_PYTHON="1")
        environment = self.deployed_environment("17-python.zsh")
        self.assertNotIn("UV_LINK_MODE", environment)

    def test_vscode_editor_integration_is_preserved(self):
        """Catch lost APP_VSCODE deployment or an EDITOR override outside VSCode."""
        self.install_custom(APP_VSCODE="1")
        for terminal, expected in (
            ("vscode", "code -w"),
            ("test-terminal", "fallback-editor"),
        ):
            with self.subTest(terminal=terminal):
                environment = self.deployed_environment(
                    "02-vscode.zsh", TERM_PROGRAM=terminal, EDITOR="fallback-editor"
                )
                self.assertEqual(environment["EDITOR"], expected)


if __name__ == "__main__":
    unittest.main()
