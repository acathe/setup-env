#!/usr/bin/env python3
"""Offline behavioral regressions for Debian's independent classic CLI flag."""

import os
from pathlib import Path
import shutil
import stat
import subprocess
import tempfile
import unittest
from contextlib import contextmanager


DEBIAN = Path(__file__).resolve().parents[1] / "debian"
CLASSIC = DEBIAN / "command" / "classic_cli"
BREW_SHELLENV = '    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv bash)"\n'

# Hand-checked output of the real classic install commands, not source-derived
# expectations. Wrong destinations, missing writes, and wrong modes must fail.
CLASSIC_FILES = {
    ".config/lesskey": (b"#env\nLESS = -RFK --mouse\n", 0o644),
    ".local/bin/nanom": (b'#!/bin/sh\n\nexec /usr/bin/nano -/ "$@"\n', 0o755),
    ".config/nano/nanorc": (
        b"set atblanks\n"
        b"set autoindent\n"
        b"set constantshow\n"
        b"set indicator\n"
        b"set linenumbers\n"
        b"set minibar\n"
        b"set mouse\n"
        b"set nohelp\n"
        b"set positionlog\n"
        b"set smarthome\n"
        b"set softwrap\n"
        b"set tabsize 4\n"
        b"set zap\n",
        0o644,
    ),
}

# name, argv, environment flags, child flags + remaining argv, files, modern
# Each expected selection/argument vector is literal and independent of Bash.
CASES = (
    ("default-off", (), {}, ["0", "0"], {}, False),
    (
        "classic-only", ("--command-classic-cli",), {},
        ["1", "0"], CLASSIC_FILES, False,
    ),
    (
        "modern-only", ("--command-modern-cli",), {},
        ["0", "1"], {}, True,
    ),
    (
        "classic-then-modern",
        ("--command-classic-cli", "--command-modern-cli"), {},
        ["1", "1"], CLASSIC_FILES, True,
    ),
    (
        "modern-then-classic",
        ("--command-modern-cli", "--command-classic-cli"), {},
        ["1", "1"], CLASSIC_FILES, True,
    ),
    (
        "repeated-flags-preserve-unknown-arguments",
        (
            "--unknown", "left right", "--command-classic-cli", "classic tail",
            "--command-modern-cli", "modern tail", "--command-classic-cli",
            "--command-modern-cli", "--keep=two words", "", "*.sh",
        ),
        {},
        [
            "1", "1", "--unknown", "left right", "classic tail", "modern tail",
            "--keep=two words", "", "*.sh",
        ],
        CLASSIC_FILES, True,
    ),
    (
        "environment-enables-classic", (), {"COMMAND_CLASSIC_CLI": "1"},
        ["1", "0"], CLASSIC_FILES, False,
    ),
    (
        "environment-disables-classic", (), {"COMMAND_CLASSIC_CLI": "0"},
        ["0", "0"], {}, False,
    ),
    (
        "environment-disables-classic-with-modern",
        (), {"COMMAND_CLASSIC_CLI": "0", "COMMAND_MODERN_CLI": "1"},
        ["0", "1"], {}, True,
    ),
    (
        "classic-flag-overrides-environment-zero",
        ("--command-classic-cli",), {"COMMAND_CLASSIC_CLI": "0"},
        ["1", "0"], CLASSIC_FILES, False,
    ),
    (
        "environment-enables-both",
        (), {"COMMAND_CLASSIC_CLI": "1", "COMMAND_MODERN_CLI": "1"},
        ["1", "1"], CLASSIC_FILES, True,
    ),
    (
        "unknown-arguments-without-flags",
        ("before spaces", "--unknown=two words", "", "*.sh"), {},
        ["0", "0", "before spaces", "--unknown=two words", "", "*.sh"],
        {}, False,
    ),
    (
        "environment-enables-only-modern", (), {"COMMAND_MODERN_CLI": "1"},
        ["0", "1"], {}, True,
    ),
)

# All external scripts invoked by debian/main.sh are replaced, not merely the
# branches selected by these cases. Only classic_cli is copied from production.
STUB_INSTALLERS = (
    "command/homebrew.sh",
    "command/omz/main.sh",
    "command/starship.sh",
    "command/modern_cli/main.sh",
    "command/ssh/main.sh",
    "code/bash.sh",
    "code/go.sh",
    "code/markdown/main.sh",
    "code/protobuf.sh",
    "code/python.sh",
    "code/rust.sh",
    "app/claude/main.sh",
    "app/docker.sh",
    "app/git/main.sh",
    "app/tmux/main.sh",
    "app/yazi/main.sh",
)

# Record the real entry's child-process environment/argv boundary. Appending
# also exposes accidentally dispatching a module twice for repeated flags.
INSTALLER_STUB = r'''#!/usr/bin/env bash
set -euo pipefail
log="$CLASSIC_CLI_TEST_LOG/${0#./}"
printf '%s\0' "${COMMAND_CLASSIC_CLI-unset}" "${COMMAND_MODERN_CLI-unset}" >> "$log"
if (($#)); then
    printf '%s\0' "$@" >> "$log"
fi
'''

# Observe the classic boundary without replacing its real configuration writes.
CLASSIC_WRAPPER = r'''#!/usr/bin/env bash
set -euo pipefail
log="$CLASSIC_CLI_TEST_LOG/command/classic_cli/main.sh"
printf '%s\0' "${COMMAND_CLASSIC_CLI-unset}" "${COMMAND_MODERN_CLI-unset}" >> "$log"
if (($#)); then
    printf '%s\0' "$@" >> "$log"
fi
exec bash "$(dirname "$0")/real-main.sh" "$@"
'''

# Source the unmodified entry only under its guard: never execute its main.
# Inspect flags in a fresh child Bash, so an unexported variable cannot pass.
PARSER_PROBE = r'''
source "$1"
shift
parse_args "$@"
bash --noprofile --norc -c '
    printf "%s\0" "${COMMAND_CLASSIC_CLI-unset}" "${COMMAND_MODERN_CLI-unset}"
    if (($#)); then printf "%s\0" "$@"; fi
' parser-child "${POSITIONAL[@]}"
'''


class ClassicCLITests(unittest.TestCase):
    maxDiff = None

    @contextmanager
    def fixture(self, flag_environment):
        # Honor the sandbox-provided TMPDIR; never hard-code a shared /tmp path.
        with tempfile.TemporaryDirectory(
            prefix="classic-cli-test-", dir=os.environ.get("TMPDIR")
        ) as directory:
            root = Path(directory)
            for name in ("home", "bin", "tmp", "trace", "debian"):
                (root / name).mkdir()

            # Permit only the harmless commands used by the entry/classic code.
            # No real installer or network command is reachable through PATH.
            for name in ("bash", "dirname", "install"):
                command = shutil.which(name)
                if command is None:
                    self.fail(f"Required test tool missing: {name}")
                (root / "bin" / name).symlink_to(command)

            entry = (DEBIAN / "main.sh").read_text()
            self.assertEqual(
                entry.count(BREW_SHELLENV), 1,
                "Refusing execution: expected exactly one absolute brew shellenv",
            )
            (root / "debian" / "main.sh").write_text(
                entry.replace(BREW_SHELLENV, "    : # offline fixture shellenv\n")
            )
            for name in STUB_INSTALLERS:
                script = root / "debian" / name
                script.parent.mkdir(parents=True, exist_ok=True)
                script.write_text(INSTALLER_STUB)
                (root / "trace" / name).parent.mkdir(parents=True, exist_ok=True)

            classic = root / "debian" / "command" / "classic_cli"
            classic.mkdir()
            for name in ("less.lesskey", "nanom", "nano.nanorc"):
                shutil.copy2(CLASSIC / name, classic / name)
            shutil.copy2(CLASSIC / "main.sh", classic / "real-main.sh")
            (classic / "main.sh").write_text(CLASSIC_WRAPPER)
            (root / "trace" / "command" / "classic_cli").mkdir()

            # Construct a fresh environment rather than inheriting COMMAND_*,
            # CODE_*, APP_*, exported functions, or shell startup settings.
            environment = {
                "HOME": str(root / "home"),
                "PATH": str(root / "bin"),
                "TMPDIR": str(root / "tmp"),
                "LC_ALL": "C",
                "BASH_ENV": "/dev/null",
                "ENV": "/dev/null",
                "CLASSIC_CLI_TEST_LOG": str(root / "trace"),
            }
            environment.update(flag_environment)
            yield root, environment

    def run_bash(self, root, environment, *arguments):
        result = subprocess.run(
            [str(root / "bin" / "bash"), "--noprofile", "--norc", *arguments],
            cwd=root, env=environment, capture_output=True, timeout=10,
        )
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        self.assertEqual(result.stderr, b"")
        return result.stdout

    def fields(self, data):
        self.assertTrue(data.endswith(b"\0"), "Missing NUL-delimited probe output")
        return data[:-1].decode().split("\0")

    def configuration(self, home):
        return {
            path.relative_to(home).as_posix(): (
                path.read_bytes(), stat.S_IMODE(path.stat().st_mode)
            )
            for path in home.rglob("*") if path.is_file()
        }

    def test_parser_consumes_flags_and_exports_them_to_a_child(self):
        # Breaks: missing classic branch/export, wrong shifts, or lost quoting.
        for name, argv, flags, want_fields, _, _ in CASES:
            with self.subTest(case=name), self.fixture(flags) as (root, environment):
                output = self.run_bash(
                    root, environment, "-c", PARSER_PROBE,
                    "parser-test", str(DEBIAN / "main.sh"), *argv,
                )
                self.assertEqual(self.fields(output), want_fields)

    def test_dispatch_selects_classic_independently_of_modern(self):
        # Breaks: unconditional classic, modern implying classic, or a gate that
        # prevents classic/nano when modern is enabled. Keep classic writes real.
        for name, argv, flags, _, want_files, want_modern in CASES:
            with self.subTest(case=name), self.fixture(flags) as (root, environment):
                output = self.run_bash(
                    root, environment, str(root / "debian" / "main.sh"), *argv,
                )
                self.assertEqual(output, b"")
                self.assertEqual(
                    (
                        self.configuration(root / "home"),
                        (root / "trace" / "command" / "modern_cli" / "main.sh").exists(),
                    ),
                    (want_files, want_modern),
                )

    def test_dispatch_exports_flags_and_forwards_only_unknown_arguments(self):
        # Breaks: failing to reset argv to POSITIONAL, losing spaces/empty args,
        # missing child exports, or repeated dispatch for repeated flags.
        for name, argv, flags, want_fields, want_files, want_modern in CASES:
            with self.subTest(case=name), self.fixture(flags) as (root, environment):
                output = self.run_bash(
                    root, environment, str(root / "debian" / "main.sh"), *argv,
                )
                self.assertEqual(output, b"")
                observed = {
                    path.relative_to(root / "trace").as_posix(): self.fields(path.read_bytes())
                    for path in (root / "trace").rglob("*") if path.is_file()
                }
                expected = {
                    "command/homebrew.sh": want_fields,
                    "command/omz/main.sh": want_fields,
                    "command/starship.sh": want_fields,
                }
                if want_files:
                    expected["command/classic_cli/main.sh"] = want_fields
                if want_modern:
                    expected["command/modern_cli/main.sh"] = want_fields
                self.assertEqual(observed, expected)

    def test_omz_nano_configuration_is_selected_by_classic(self):
        # Breaks: default nano config referring to an unselected nanom, or
        # modern suppressing classic's custom file when both are selected.
        for name, flags, want in (
            ("default-off", {}, ()),
            ("classic-only", {"COMMAND_CLASSIC_CLI": "1"}, ("00-nano.zsh",)),
            ("modern-only", {"COMMAND_MODERN_CLI": "1"}, ("01-micro.zsh",)),
            (
                "both-enabled",
                {"COMMAND_CLASSIC_CLI": "1", "COMMAND_MODERN_CLI": "1"},
                ("00-nano.zsh", "01-micro.zsh"),
            ),
        ):
            with self.subTest(case=name), self.fixture(flags) as (root, environment):
                custom = root / "home" / ".oh-my-zsh" / "custom"
                custom.mkdir(parents=True)
                environment["ZSH_CUSTOM"] = str(custom)
                output = self.run_bash(
                    root, environment, str(DEBIAN / "command" / "omz" / "custom.sh"),
                )
                self.assertEqual(output, b"")
                self.assertEqual(
                    tuple(
                        filename for filename in ("00-nano.zsh", "01-micro.zsh")
                        if (custom / filename).is_file()
                    ),
                    want,
                )

    def test_real_classic_always_writes_less_and_nano_with_correct_modes(self):
        # Breaks: classic reading modern to skip nano, wrong install source,
        # destination, file content, or mode. Never execute the installed nanom.
        for name, flags in (
            ("modern-unset", {}),
            ("modern-disabled", {"COMMAND_MODERN_CLI": "0"}),
            ("modern-enabled", {"COMMAND_MODERN_CLI": "1"}),
        ):
            with self.subTest(case=name), self.fixture(flags) as (root, environment):
                output = self.run_bash(
                    root, environment,
                    str(root / "debian" / "command" / "classic_cli" / "main.sh"),
                )
                self.assertEqual(output, b"")
                self.assertEqual(self.configuration(root / "home"), CLASSIC_FILES)


if __name__ == "__main__":
    unittest.main(verbosity=2)
