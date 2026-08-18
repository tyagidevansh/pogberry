from __future__ import annotations

import subprocess
import sys
import tempfile
from pathlib import Path


def write(path: Path, source: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(source, encoding="utf-8")


def command(
    binary: Path,
    arguments: list[str | Path],
    input_text: str | None = None,
    cwd: Path | None = None,
) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [str(binary), *(str(argument) for argument in arguments)],
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        input=input_text,
        cwd=cwd,
        check=False,
    )


def run(
    binary: Path, entry: Path, input_text: str | None = None
) -> subprocess.CompletedProcess[str]:
    return command(binary, [entry], input_text)


def require(condition: bool, message: str) -> None:
    if not condition:
        raise RuntimeError(message)


def main() -> int:
    binary = Path(sys.argv[1]).resolve()
    repository = Path(__file__).resolve().parents[2]
    example = run(
        binary,
        repository / "examples" / "module_project" / "main.pb",
        "Ada\n1\n1\n1\n1\n2\n1\n",
    )
    require(example.returncode == 0, "module project example failed")
    require(
        "Welcome, Ada." in example.stdout
        and "You recover 30 health." in example.stdout
        and "Victory!" in example.stdout
        and "Total experience: 40" in example.stdout,
        "module project example output",
    )

    guiExample = run(
        binary,
        repository / "examples" / "games" / "gui_project" / "main.pb",
    )
    require(guiExample.returncode == 0, "GUI module project failed")

    with tempfile.TemporaryDirectory() as temporary:
        root = Path(temporary)
        project = root / "project"

        write(
            project / "main.pb",
            'use "player";\n'
            'use "game/rules";\n'
            'use "game/rules" as sameRules;\n'
            'print(player.remaining(3));\n'
            'print(rules == sameRules);\n',
        )
        write(
            project / "player.pb",
            'use "game/rules";\n'
            'print("player loaded");\n'
            'export fun remaining(level) {\n'
            '  return rules.startingHealth - rules.damage(level);\n'
            '}\n',
        )
        write(
            project / "game" / "rules.pb",
            'print("rules loaded");\n'
            'export let startingHealth = 100;\n'
            'export fun damage(level) { return level * 5; }\n',
        )

        result = run(binary, project / "main.pb")
        require(result.returncode == 0, "multi-file project failed")
        require(
            result.stdout == "rules loaded\nplayer loaded\n85\ntrue\n",
            "nested imports or module caching failed",
        )

        expected = "rules loaded\nplayer loaded\n85\ntrue\n"
        result = command(binary, ["run", project / "main.pb"])
        require(result.returncode == 0, "file run command failed")
        require(result.stdout == expected, "file run command output")

        result = command(binary, ["run", project])
        require(result.returncode == 0, "directory run command failed")
        require(result.stdout == expected, "directory run command output")

        result = command(binary, ["run"], cwd=project)
        require(result.returncode == 0, "current-directory run command failed")
        require(result.stdout == expected, "current-directory run command output")

        result = command(binary, [project])
        require(result.returncode == 0, "legacy directory command failed")
        require(result.stdout == expected, "legacy directory command output")

        result = command(binary, ["repl"], 'print("repl ready");\n')
        require(result.returncode == 0, "repl command failed")
        require("repl ready" in result.stdout, "repl command output")

        result = command(binary, ["--help"])
        require(result.returncode == 0, "help command failed")
        require("pb run [path]" in result.stdout, "help command output")

        write(project / "missing.pb", 'use "unknown" as unknown;\n')
        result = run(binary, project / "missing.pb")
        require(result.returncode == 70, "missing module status")
        require(
            "Could not find module 'unknown'." in result.stdout,
            "missing module diagnostic",
        )

        write(root / "secret.pb", 'print("escaped"); export let value = 1;\n')
        write(project / "unsafe.pb", 'use "../secret" as secret;\n')
        result = run(binary, project / "unsafe.pb")
        require(result.returncode == 70, "unsafe module status")
        require("escaped" not in result.stdout, "module escaped project root")
        require(
            "Invalid module name '../secret'." in result.stdout,
            "unsafe module diagnostic",
        )

    print("CLI module test passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
