import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[2]
MAGPIE = REPO / "container/magpie/main.sh"
CONTAINER = REPO / "container/main.sh"
BASH = shutil.which("bash") or ""
ZSH = shutil.which("zsh") or ""
GENERATED_KEY = "0123456789abcdef0123456789abcdef"
OLD_CONTAINER = "123456789abc"
IMAGE = "ghcr.io/yetone/magpie:latest"
UPDATE_URL = "https://raw.githubusercontent.com/acathe/setup-env/master/main.sh"
ENV_FORMAT = "{{range .Config.Env}}{{println .}}{{end}}"

BOOTSTRAP = r'''
record() {
    local tool="$1" argument
    shift
    printf '%s\0%d\0' "$tool" "$#" >> "$TEST_TRACE"
    for argument in "$@"; do
        printf '%s\0' "$argument" >> "$TEST_TRACE"
    done
}
docker() {
    record docker "$@"
    case "$1" in
        ps)
            printf '%s' "$TEST_CONTAINER_ID"
            return "${TEST_PS_EXIT:-0}"
            ;;
        inspect)
            if [[ ${TEST_INSPECT_EXIT:-0} != 0 ]]; then
                return "$TEST_INSPECT_EXIT"
            fi
            printf '%s\n' 'MAGPIE_ADDR=0.0.0.0:3425'
            if [[ ${TEST_KEY_PRESENT:-1} == 1 ]]; then
                printf 'MAGPIE_WEB_KEY=%s\n' "$TEST_WEB_KEY"
            fi
            return 0
            ;;
        pull) return "${TEST_PULL_EXIT:-0}" ;;
        rm) return "${TEST_RM_EXIT:-0}" ;;
        run)
            printf '%s\n' 'new-magpie-container'
            return "${TEST_RUN_EXIT:-0}"
            ;;
        *) return 97 ;;
    esac
}
openssl() {
    record openssl "$@"
    if [[ ${TEST_OPENSSL_EXIT:-0} != 0 ]]; then
        return "$TEST_OPENSSL_EXIT"
    fi
    printf '%s\n' "$TEST_GENERATED_KEY"
}
curl() {
    record curl "$@"
    if [[ ${TEST_CURL_EXIT:-0} != 0 && ${TEST_CURL_PARTIAL:-0} != 1 ]]; then
        return "$TEST_CURL_EXIT"
    fi
    printf '%s\n' \
        'printf "entry\0%d\0" "$#" >> "$TEST_TRACE"' \
        'for argument in "$@"; do' \
        '    printf "%s\0" "$argument" >> "$TEST_TRACE"' \
        'done' \
        'exit "${TEST_UPDATE_EXIT:-0}"'
    return "${TEST_CURL_EXIT:-0}"
}
export -f record docker openssl curl
'''


def run_args(key):
    return [
        "run", "-d", "--name", "magpie", "--restart", "unless-stopped",
        "-p", "127.0.0.1:3425:3425", "-p", "192.168.80.200:3425:3425",
        "-p", "192.168.80.200:3430:3430",
        "-e", "MAGPIE_PUBLIC_URL=http://192.168.80.200:3425",
        "-e", "MAGPIE_WEB_KEY=" + key,
        "-v", "magpie-config:/config", IMAGE,
        "web", "--addr", "0.0.0.0:3430", "--no-open",
    ]


class MagpieFixture(unittest.TestCase):
    def setUp(self):
        self.workspace = tempfile.TemporaryDirectory(
            prefix="magpie-tests-", dir=os.environ.get("TMPDIR")
        )
        self.addCleanup(self.workspace.cleanup)
        self.root = Path(self.workspace.name)
        self.home = self.root / "home with spaces"
        self.home.mkdir()
        self.trace = self.root / "commands.bin"
        self.bin = self.root / "bin"
        self.bin.mkdir()
        for tool in ("docker", "openssl", "curl"):
            shim = self.bin / tool
            shim.write_text(
                "#!" + BASH + "\n" + BOOTSTRAP + f'\n{tool} "$@"\n'
            )
            shim.chmod(0o700)

    def environment(self, **overrides):
        environment = {
            "PATH": str(self.bin) + os.pathsep + os.environ.get("PATH", "/usr/bin:/bin"),
            "HOME": str(self.home),
            "IMAGE": "",
            "TEST_BASH": BASH,
            "TEST_TRACE": str(self.trace),
            "TEST_CONTAINER_ID": "",
            "TEST_WEB_KEY": "existing key=with spaces",
            "TEST_GENERATED_KEY": GENERATED_KEY,
        }
        environment.update(overrides)
        return environment

    def run_shell(self, command, *args, **overrides):
        return subprocess.run(
            [BASH, "--noprofile", "--norc", "-c", BOOTSTRAP + command,
             "magpie-test", *map(str, args)],
            cwd=self.home,
            env=self.environment(**overrides),
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )

    def run_script(self, script=MAGPIE, *args, **overrides):
        return self.run_shell(
            '\nexec "$TEST_BASH" --noprofile --norc "$@"\n',
            script, *args, **overrides
        )

    def calls(self):
        if not self.trace.exists():
            return []
        fields = self.trace.read_bytes().decode().split("\0")[:-1]
        result = []
        index = 0
        while index < len(fields):
            tool, count = fields[index:index + 2]
            count = int(count)
            arguments = fields[index + 2:index + 2 + count]
            result.append((tool, arguments))
            index += count + 2
        return result

    def docker_calls(self):
        return [args for tool, args in self.calls() if tool == "docker"]

    def assert_deployed(self, result, key=GENERATED_KEY):
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        self.assertEqual(result.stderr, b"")
        runs = [args for args in self.docker_calls() if args[0] == "run"]
        self.assertEqual(runs, [run_args(key)])

    def hook_path(self, custom=None):
        custom = Path(custom) if custom is not None else self.home / ".oh-my-zsh/custom"
        return custom / "plugins/update-all-in-one/custom/98-magpie.zsh"

    def install_hook(self, **overrides):
        result = self.run_script(MAGPIE, "--add-update-config", **overrides)
        self.assert_deployed(result)
        hook = self.hook_path(overrides.get("ZSH_CUSTOM"))
        self.assertTrue(hook.is_file(), "Magpie update hook was not installed")
        return hook

    def run_plugin(self, platform="debian", custom=None, **overrides):
        custom = Path(custom) if custom is not None else self.home / ".oh-my-zsh/custom"
        plugin = REPO / platform / "command/omz/plugins/update-all-in-one/update-all-in-one.plugin.zsh"
        command = r'''
unsetopt pipe_fail
source "$1"
update-all-in-one
update_result=$?
if [[ -o pipefail ]]; then
    printf '%s\n' 'Update hook leaked pipefail into its caller' >&2
    exit 98
fi
exit "$update_result"
'''
        return subprocess.run(
            [ZSH, "-f", "-c", command, "magpie-hook-test", str(plugin)],
            cwd=self.home,
            env=self.environment(ZSH_CUSTOM=str(custom), **overrides),
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )


@unittest.skipUnless(BASH, "Bash is required")
class TestDeployment(MagpieFixture):
    def test_direct_entry_uses_requested_arguments(self):
        self.assert_deployed(self.run_script())

    def test_container_cli_dispatch(self):
        self.assert_deployed(self.run_script(CONTAINER, "--image", "magpie"))

    def test_container_environment_dispatch(self):
        self.assert_deployed(self.run_script(CONTAINER, IMAGE="magpie"))

    def test_cli_image_overrides_environment(self):
        self.assert_deployed(self.run_script(
            CONTAINER, "--image", "magpie", IMAGE="copilot-api"
        ))

    def test_unknown_image_never_calls_docker(self):
        result = self.run_script(CONTAINER, "--image", "unknown")
        self.assertEqual(result.returncode, 1)
        self.assertEqual(result.stderr, b"Unsupported image: unknown\n")
        self.assertEqual(self.calls(), [])

    def test_docker_failure_is_propagated(self):
        result = self.run_script(TEST_RUN_EXIT="19")
        self.assertEqual(result.returncode, 19, result.stderr.decode())

    def test_source_is_safe(self):
        result = self.run_shell('\nsource "$1"\n', MAGPIE)
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        self.assertEqual(self.calls(), [])

    def test_sourced_main_can_deploy(self):
        self.assert_deployed(self.run_shell('\nsource "$1"\nmain\n', MAGPIE))


@unittest.skipUnless(BASH, "Bash is required")
class TestUpdate(MagpieFixture):
    def test_first_install_pulls_and_starts(self):
        self.assert_deployed(self.run_script())
        self.assertEqual(self.calls(), [
            ("docker", ["ps", "-aq", "--filter", "name=^/magpie$"]),
            ("openssl", ["rand", "-hex", "16"]),
            ("docker", ["pull", IMAGE]),
            ("docker", run_args(GENERATED_KEY)),
        ])

    def test_existing_container_preserves_key_and_is_replaced(self):
        key = " saved key=with spaces\\and a trailing space "
        result = self.run_script(TEST_CONTAINER_ID=OLD_CONTAINER, TEST_WEB_KEY=key)
        self.assert_deployed(result, key)
        self.assertEqual(self.docker_calls(), [
            ["ps", "-aq", "--filter", "name=^/magpie$"],
            ["inspect", "--format", ENV_FORMAT, OLD_CONTAINER],
            ["pull", IMAGE],
            ["rm", "-f", OLD_CONTAINER],
            run_args(key),
        ])
        self.assertFalse(any(tool == "openssl" for tool, _ in self.calls()))

    def test_existing_container_without_key_gets_a_new_key(self):
        self.assert_deployed(self.run_script(
            TEST_CONTAINER_ID=OLD_CONTAINER, TEST_KEY_PRESENT="0"
        ))
        self.assertIn(("openssl", ["rand", "-hex", "16"]), self.calls())
        self.assertIn(["rm", "-f", OLD_CONTAINER], self.docker_calls())

    def test_container_query_failure_stops_before_mutation(self):
        result = self.run_script(TEST_PS_EXIT="41")
        self.assertEqual(result.returncode, 41, result.stderr.decode())
        self.assertEqual(self.calls(), [
            ("docker", ["ps", "-aq", "--filter", "name=^/magpie$"]),
        ])

    def test_inspect_failure_preserves_the_existing_container(self):
        result = self.run_script(TEST_CONTAINER_ID=OLD_CONTAINER, TEST_INSPECT_EXIT="35")
        self.assertEqual(result.returncode, 35, result.stderr.decode())
        self.assertEqual(self.docker_calls(), [
            ["ps", "-aq", "--filter", "name=^/magpie$"],
            ["inspect", "--format", ENV_FORMAT, OLD_CONTAINER],
        ])
        self.assertFalse(any(tool == "openssl" for tool, _ in self.calls()))

    def test_key_generation_failure_does_not_start_a_container(self):
        result = self.run_script(TEST_OPENSSL_EXIT="11")
        self.assertEqual(result.returncode, 11, result.stderr.decode())
        self.assertEqual(self.calls(), [
            ("docker", ["ps", "-aq", "--filter", "name=^/magpie$"]),
            ("openssl", ["rand", "-hex", "16"]),
        ])

    def test_pull_failure_keeps_the_old_container(self):
        result = self.run_script(TEST_CONTAINER_ID=OLD_CONTAINER, TEST_PULL_EXIT="12")
        self.assertEqual(result.returncode, 12, result.stderr.decode())
        self.assertEqual(self.docker_calls(), [
            ["ps", "-aq", "--filter", "name=^/magpie$"],
            ["inspect", "--format", ENV_FORMAT, OLD_CONTAINER],
            ["pull", IMAGE],
        ])

    def test_remove_failure_prevents_replacement(self):
        result = self.run_script(TEST_CONTAINER_ID=OLD_CONTAINER, TEST_RM_EXIT="17")
        self.assertEqual(result.returncode, 17, result.stderr.decode())
        self.assertEqual(self.docker_calls()[-1], ["rm", "-f", OLD_CONTAINER])
        self.assertFalse(any(args[0] == "run" for args in self.docker_calls()))

    def test_updates_are_not_registered_by_default(self):
        self.assert_deployed(self.run_script())
        self.assertFalse(self.hook_path().exists())

    def test_install_update_via_cli(self):
        result = self.run_script(CONTAINER, "--image", "magpie", "--add-update-config")
        self.assert_deployed(result)
        hook = self.hook_path()
        self.assertTrue(hook.is_file(), "Magpie update hook was not installed")
        self.assertEqual(hook.stat().st_mode & 0o777, 0o644)

    def test_install_update_via_environment(self):
        self.assert_deployed(self.run_script(MAGPIE_ADD_UPDATE_CONFIG="1"))
        self.assertTrue(self.hook_path().is_file(), "Magpie update hook was not installed")

    def test_custom_zsh_directory_is_honored(self):
        custom = self.root / "custom zsh directory"
        hook = self.install_hook(ZSH_CUSTOM=str(custom))
        self.assertTrue(hook.is_file())
        self.assertFalse(self.hook_path().exists())

    def test_failed_deployment_does_not_install_the_hook(self):
        result = self.run_script(MAGPIE, "--add-update-config", TEST_RUN_EXIT="19")
        self.assertEqual(result.returncode, 19, result.stderr.decode())
        self.assertFalse(self.hook_path().exists())

    def test_parse_args_preserves_other_arguments(self):
        command = r'''
source "$1"
shift
parse_args "$@"
printf '%s\0' "$MAGPIE_ADD_UPDATE_CONFIG" "${POSITIONAL[@]}"
'''
        result = self.run_shell(command, MAGPIE, "--add-update-config", "--other", "a b", "tail")
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        self.assertEqual(result.stdout, b"1\0--other\0a b\0tail\0")
        self.assertEqual(self.calls(), [])

    def test_conditional_main_preserves_all_failure_boundaries(self):
        query = ("docker", ["ps", "-aq", "--filter", "name=^/magpie$"])
        inspect = ("docker", ["inspect", "--format", ENV_FORMAT, OLD_CONTAINER])
        generate = ("openssl", ["rand", "-hex", "16"])
        pull = ("docker", ["pull", IMAGE])
        remove = ("docker", ["rm", "-f", OLD_CONTAINER])
        cases = [
            ("query", {"TEST_PS_EXIT": "41"}, 41, [query]),
            ("inspect", {"TEST_CONTAINER_ID": OLD_CONTAINER, "TEST_INSPECT_EXIT": "35"},
             35, [query, inspect]),
            ("key", {"TEST_OPENSSL_EXIT": "11"}, 11, [query, generate]),
            ("pull", {"TEST_CONTAINER_ID": OLD_CONTAINER, "TEST_PULL_EXIT": "12"},
             12, [query, inspect, pull]),
            ("remove", {"TEST_CONTAINER_ID": OLD_CONTAINER, "TEST_RM_EXIT": "17"},
             17, [query, inspect, pull, remove]),
            ("run", {"TEST_RUN_EXIT": "19", "MAGPIE_ADD_UPDATE_CONFIG": "1"},
             19, [query, generate, pull, ("docker", run_args(GENERATED_KEY))]),
        ]
        command = r'''
source "$1"
if main; then
    exit 0
else
    exit "$?"
fi
'''
        for step, overrides, expected_exit, expected_calls in cases:
            with self.subTest(step=step):
                start = len(self.calls())
                result = self.run_shell(command, MAGPIE, **overrides)
                self.assertEqual(result.returncode, expected_exit, result.stderr.decode())
                self.assertEqual(self.calls()[start:], expected_calls)
                self.assertFalse(self.hook_path().exists())

    def test_sourced_update_install_survives_a_working_directory_change(self):
        destination = self.root / "changed working directory"
        destination.mkdir()
        relative_source = os.path.relpath(MAGPIE, self.home)
        command = r'''
source "$1"
cd "$2"
main
'''
        result = self.run_shell(
            command, relative_source, destination, MAGPIE_ADD_UPDATE_CONFIG="1"
        )
        self.assert_deployed(result)
        self.assertTrue(self.hook_path().is_file())


@unittest.skipUnless(BASH and ZSH, "Bash and Zsh are required")
class TestHook(MagpieFixture):
    def test_hook_uses_remote_entry_on_both_platforms(self):
        self.install_hook()
        for platform in ("debian", "macos"):
            with self.subTest(platform=platform):
                start = len(self.calls())
                result = self.run_plugin(platform)
                self.assertEqual(result.returncode, 0, result.stderr.decode())
                self.assertEqual(result.stderr, b"")
                self.assertEqual(self.calls()[start:], [
                    ("curl", ["-fsSL", UPDATE_URL]),
                    ("entry", ["--setup", "container", "--image", "magpie"]),
                ])

    def test_hook_download_failure_is_returned(self):
        self.install_hook()
        result = self.run_plugin(TEST_CURL_EXIT="22")
        self.assertEqual(result.returncode, 22, result.stderr.decode())
        self.assertFalse(any(tool == "entry" for tool, _ in self.calls()))

    def test_partial_failed_download_never_executes_received_code(self):
        self.install_hook()
        result = self.run_plugin(TEST_CURL_EXIT="22", TEST_CURL_PARTIAL="1")
        self.assertEqual(result.returncode, 22, result.stderr.decode())
        self.assertFalse(any(tool == "entry" for tool, _ in self.calls()))

    def test_hook_update_failure_is_returned(self):
        self.install_hook()
        result = self.run_plugin(TEST_UPDATE_EXIT="23")
        self.assertEqual(result.returncode, 23, result.stderr.decode())

    def test_hook_honors_custom_zsh_directory(self):
        custom = self.root / "custom zsh directory"
        self.install_hook(ZSH_CUSTOM=str(custom))
        result = self.run_plugin(custom=custom)
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        self.assertIn(("entry", ["--setup", "container", "--image", "magpie"]), self.calls())


if __name__ == "__main__":
    unittest.main(verbosity=2)
