from __future__ import annotations

import subprocess
import sys
import tempfile
from pathlib import Path


def write(path: Path, source: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(source, encoding="utf-8")


def run(binary: Path, entry: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [str(binary), str(entry)],
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        check=False,
    )


def require(condition: bool, message: str) -> None:
    if not condition:
        raise RuntimeError(message)


def main() -> int:
    binary = Path(sys.argv[1]).resolve()
    repository = Path(__file__).resolve().parents[2]
    example = run(binary, repository / "examples" / "module_project" / "main.pb")
    require(example.returncode == 0, "module project example failed")
    require(
        example.stdout
        == "Battle begins\nMira\nCave slime\n14\n10\n14\n10\n14\n10\n14\n10\n30\n14\nVictory\n90\n40\n40\n",
        "module project example output",
    )

    with tempfile.TemporaryDirectory() as temporary:
        root = Path(temporary)
        project = root / "project"

        write(
            project / "main.pb",
            'use "player" as player;\n'
            'use "game/rules" as rules;\n'
            'use "game/rules" as sameRules;\n'
            'print(player.remaining(3));\n'
            'print(rules == sameRules);\n',
        )
        write(
            project / "player.pb",
            'use "game/rules" as rules;\n'
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
