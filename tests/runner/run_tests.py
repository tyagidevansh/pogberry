from __future__ import annotations

import argparse
import difflib
import os
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass
from pathlib import Path


OUTPUT_START = "// EXPECTED OUTPUT:"
OUTPUT_END = "// END EXPECTED OUTPUT"
STATUS_PREFIX = "// EXPECTED STATUS:"


@dataclass(frozen=True)
class Expectations:
    status: int
    output: str


@dataclass(frozen=True)
class Result:
    path: Path
    elapsed: float
    expected: Expectations | None = None
    actual_status: int | None = None
    actual_output: str = ""
    problem: str | None = None

    @property
    def passed(self) -> bool:
        return (
            self.problem is None
            and self.expected is not None
            and self.actual_status == self.expected.status
            and self.actual_output == self.expected.output
        )


class Style:
    def __init__(self, enabled: bool) -> None:
        self.enabled = enabled

    def paint(self, code: str, value: str) -> str:
        return f"\033[{code}m{value}\033[0m" if self.enabled else value

    def bold(self, value: str) -> str:
        return self.paint("1", value)

    def green(self, value: str) -> str:
        return self.paint("32", value)

    def red(self, value: str) -> str:
        return self.paint("31", value)

    def yellow(self, value: str) -> str:
        return self.paint("33", value)

    def dim(self, value: str) -> str:
        return self.paint("2", value)


def parse_expectations(source: Path) -> Expectations:
    status = 0
    status_seen = False
    output_lines: list[str] = []
    in_output = False
    output_seen = False

    for line_number, line in enumerate(source.read_text(encoding="utf-8").splitlines(), 1):
        if line.startswith(STATUS_PREFIX):
            if status_seen:
                raise ValueError(f"line {line_number}: duplicate expected status")
            status_seen = True
            raw_status = line[len(STATUS_PREFIX) :].strip()
            try:
                status = int(raw_status)
            except ValueError as error:
                raise ValueError(f"line {line_number}: invalid expected status {raw_status!r}") from error
            continue

        if line == OUTPUT_START:
            if in_output or output_seen:
                raise ValueError(f"line {line_number}: duplicate expected output block")
            in_output = True
            output_seen = True
            continue

        if line == OUTPUT_END:
            if not in_output:
                raise ValueError(f"line {line_number}: unexpected expected output terminator")
            in_output = False
            continue

        if in_output:
            if not line.startswith("//|"):
                raise ValueError(f"line {line_number}: expected output lines must start with '//|'")
            output_lines.append(line[3:])

    if in_output:
        raise ValueError("unterminated expected output block")
    if not output_seen:
        raise ValueError("missing expected output block")

    output = "\n".join(output_lines)
    if output_lines:
        output += "\n"
    return Expectations(status, output)


def normalize_output(output: bytes) -> str:
    return output.decode("utf-8", errors="replace").replace("\r\n", "\n").replace("\r", "\n")


def run_case(binary: Path, source: Path, timeout: float) -> Result:
    started = time.perf_counter()
    try:
        expected = parse_expectations(source)
    except (OSError, UnicodeError, ValueError) as error:
        return Result(source, time.perf_counter() - started, problem=f"invalid metadata: {error}")

    try:
        completed = subprocess.run(
            [str(binary), str(source)],
            cwd=binary.parent.parent,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            check=False,
            timeout=timeout,
        )
    except subprocess.TimeoutExpired as error:
        output = normalize_output(error.stdout or b"")
        return Result(
            source,
            time.perf_counter() - started,
            expected=expected,
            actual_output=output,
            problem=f"timed out after {timeout:g}s",
        )
    except OSError as error:
        return Result(source, time.perf_counter() - started, expected=expected, problem=str(error))

    return Result(
        source,
        time.perf_counter() - started,
        expected=expected,
        actual_status=completed.returncode,
        actual_output=normalize_output(completed.stdout),
    )


def select_cases(cases_root: Path, selectors: list[str]) -> list[Path]:
    all_cases = sorted(cases_root.rglob("*.pb"))
    if not selectors:
        return all_cases

    selected: set[Path] = set()
    for raw_selector in selectors:
        selector = raw_selector.replace("\\", "/").strip("/").casefold()
        matches = [
            case
            for case in all_cases
            if selector in case.relative_to(cases_root).as_posix().casefold()
        ]
        if not matches:
            raise ValueError(f"selector matched no tests: {raw_selector}")
        selected.update(matches)
    return sorted(selected)


def output_diff(expected: str, actual: str) -> str:
    return "".join(
        difflib.unified_diff(
            expected.splitlines(keepends=True),
            actual.splitlines(keepends=True),
            fromfile="expected",
            tofile="actual",
        )
    )


def print_failure(result: Result, cases_root: Path, style: Style) -> None:
    relative = result.path.relative_to(cases_root).as_posix()
    print(f"\n{style.red(style.bold('FAIL'))} {relative}")
    if result.problem is not None:
        print(f"  {result.problem}")
    if result.expected is None:
        return
    if result.actual_status != result.expected.status:
        actual = "not available" if result.actual_status is None else str(result.actual_status)
        print(f"  exit status: expected {result.expected.status}, got {actual}")
    if result.actual_output != result.expected.output:
        diff = output_diff(result.expected.output, result.actual_output)
        if diff:
            for line in diff.rstrip().splitlines():
                if line.startswith("+") and not line.startswith("+++"):
                    print(style.green(line))
                elif line.startswith("-") and not line.startswith("---"):
                    print(style.red(line))
                else:
                    print(line)
        else:
            print("  output differs, but no line diff was available")


def run_serial(binary: Path, cases: list[Path], timeout: float, fail_fast: bool) -> list[Result]:
    results: list[Result] = []
    for case in cases:
        result = run_case(binary, case, timeout)
        results.append(result)
        if fail_fast and not result.passed:
            break
    return results


def run_parallel(binary: Path, cases: list[Path], timeout: float, jobs: int) -> list[Result]:
    results: list[Result] = []
    with ThreadPoolExecutor(max_workers=jobs) as executor:
        futures = {executor.submit(run_case, binary, case, timeout): case for case in cases}
        for future in as_completed(futures):
            results.append(future.result())
    return sorted(results, key=lambda result: result.path)


def default_jobs() -> int:
    return min(8, max(1, os.cpu_count() or 1))


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Run Pogberry language tests.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument("selectors", nargs="*", help="path fragments used to select test cases")
    parser.add_argument("--binary", type=Path, help="path to the Pogberry executable")
    parser.add_argument("--timeout", type=float, default=5.0, help="timeout for each case in seconds")
    parser.add_argument("--jobs", type=int, default=default_jobs(), help="maximum parallel test processes")
    parser.add_argument("--list", action="store_true", help="list selected tests without running them")
    parser.add_argument("--fail-fast", action="store_true", help="stop after the first failure")
    parser.add_argument("--verbose", action="store_true", help="show every passing test")
    parser.add_argument("--no-color", action="store_true", help="disable ANSI colors")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.timeout <= 0:
        print("error: --timeout must be greater than zero", file=sys.stderr)
        return 2
    if args.jobs <= 0:
        print("error: --jobs must be greater than zero", file=sys.stderr)
        return 2

    runner_dir = Path(__file__).resolve().parent
    tests_root = runner_dir.parent
    project_root = tests_root.parent
    cases_root = tests_root / "cases"
    default_binary = project_root / "build" / ("pb.exe" if os.name == "nt" else "pb")
    binary = (args.binary or default_binary).resolve()
    color_enabled = not args.no_color and "NO_COLOR" not in os.environ and sys.stdout.isatty()
    style = Style(color_enabled)

    try:
        cases = select_cases(cases_root, args.selectors)
    except ValueError as error:
        print(f"error: {error}", file=sys.stderr)
        return 2

    if not cases:
        print(f"error: no .pb tests found under {cases_root}", file=sys.stderr)
        return 2

    if args.list:
        for case in cases:
            print(case.relative_to(cases_root).as_posix())
        print(f"\n{len(cases)} test{'s' if len(cases) != 1 else ''}")
        return 0

    if not binary.is_file():
        print(f"error: test binary not found: {binary}", file=sys.stderr)
        return 2

    try:
        binary_label = binary.relative_to(project_root)
    except ValueError:
        binary_label = binary

    print(style.bold("Pogberry test suite"))
    print(f"  binary  {binary_label}")
    print(f"  cases   {len(cases)}")
    print(f"  workers {1 if args.fail_fast else min(args.jobs, len(cases))}")

    started = time.perf_counter()
    if args.fail_fast or args.jobs == 1:
        results = run_serial(binary, cases, args.timeout, args.fail_fast)
    else:
        results = run_parallel(binary, cases, args.timeout, args.jobs)
    elapsed = time.perf_counter() - started

    for result in results:
        relative = result.path.relative_to(cases_root).as_posix()
        if result.passed:
            if args.verbose:
                print(f"{style.green('PASS')} {relative} {style.dim(f'{result.elapsed * 1000:.0f}ms')}")
        else:
            print_failure(result, cases_root, style)

    passed = sum(result.passed for result in results)
    failed = len(results) - passed
    skipped = len(cases) - len(results)
    print()
    if failed == 0:
        verdict = style.green(style.bold(f"{passed} passed"))
    else:
        verdict = f"{style.green(f'{passed} passed')}, {style.red(style.bold(f'{failed} failed'))}"
    if skipped:
        verdict += f", {style.yellow(f'{skipped} not run')}"
    print(f"{verdict} in {elapsed:.2f}s")
    return 0 if failed == 0 and skipped == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
