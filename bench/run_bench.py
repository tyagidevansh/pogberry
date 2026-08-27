#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import math
import os
import platform
import re
import statistics
import subprocess
import sys
import tempfile
import time
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional


# ── Styling ──────────────────────────────────────────────────────────

class Style:
    """ANSI terminal colours and formatting."""

    def __init__(self, enabled: bool) -> None:
        self.enabled = enabled

    def _wrap(self, code: str, text: str) -> str:
        if not self.enabled:
            return text
        return f"\033[{code}m{text}\033[0m"

    def bold(self, t: str) -> str:
        return self._wrap("1", t)

    def dim(self, t: str) -> str:
        return self._wrap("2", t)

    def green(self, t: str) -> str:
        return self._wrap("32", t)

    def red(self, t: str) -> str:
        return self._wrap("31", t)

    def yellow(self, t: str) -> str:
        return self._wrap("33", t)

    def cyan(self, t: str) -> str:
        return self._wrap("36", t)

    def magenta(self, t: str) -> str:
        return self._wrap("35", t)


ANSI_REGEX = re.compile(r"\033\[[0-9;]*m")


def visible_length(s: str) -> int:
    """Return visible width of string excluding ANSI escape codes."""
    return len(ANSI_REGEX.sub("", s))


def pad_vis(s: str, width: int, align: str = "left") -> str:
    """Pad string to visible width taking into account ANSI escape codes."""
    vis = visible_length(s)
    pad = max(0, width - vis)
    if align == "right":
        return (" " * pad) + s
    elif align == "center":
        left = pad // 2
        right = pad - left
        return (" " * left) + s + (" " * right)
    return s + (" " * pad)


def pad_box_row(content: str, width: int, style: Style) -> str:
    """Wrap content inside left and right box border characters with exact padding."""
    vis_len = visible_length(content)
    pad = max(0, width - 2 - vis_len)
    return (style.bold(style.cyan("│")) + content + (" " * pad) +
            style.bold(style.cyan("│")))


# ── Data structures ──────────────────────────────────────────────────

@dataclass
class PerfCounters:
    """Hardware counters from one perf-stat invocation."""
    instructions: Optional[int] = None
    cycles: Optional[int] = None
    cache_misses: Optional[int] = None
    branch_misses: Optional[int] = None

    @property
    def ipc(self) -> Optional[float]:
        if self.instructions and self.cycles and self.cycles > 0:
            return self.instructions / self.cycles
        return None


@dataclass
class RunResult:
    """Outcome of a single benchmark run."""
    wall_time: float           # seconds
    output: str = ""
    perf: Optional[PerfCounters] = None


@dataclass
class BenchmarkResult:
    """Aggregated results for one runtime on one benchmark."""
    runs: list[RunResult] = field(default_factory=list)

    @property
    def times(self) -> list[float]:
        return [r.wall_time for r in self.runs]

    @property
    def median(self) -> float:
        return statistics.median(self.times) if self.times else 0.0

    @property
    def mean(self) -> float:
        return statistics.mean(self.times) if self.times else 0.0

    @property
    def stdev(self) -> float:
        return statistics.stdev(self.times) if len(self.times) >= 2 else 0.0

    @property
    def best(self) -> float:
        return min(self.times) if self.times else 0.0

    @property
    def worst(self) -> float:
        return max(self.times) if self.times else 0.0

    @property
    def last_perf(self) -> Optional[PerfCounters]:
        for r in reversed(self.runs):
            if r.perf is not None:
                return r.perf
        return None

    @property
    def output(self) -> str:
        return self.runs[0].output if self.runs else ""


@dataclass
class BenchmarkEntry:
    """One benchmark with results for all runtimes."""
    name: str
    is_gui: bool = False
    pogberry: Optional[BenchmarkResult] = None
    python: Optional[BenchmarkResult] = None
    python_jit: Optional[BenchmarkResult] = None
    correct: bool = True
    error: str = ""


# ── Environment detection ────────────────────────────────────────────

def detect_gcc_version() -> str:
    try:
        out = subprocess.run(
            ["gcc", "--version"], capture_output=True, text=True, timeout=5
        )
        first_line = out.stdout.splitlines()[0] if out.stdout else "unknown"
        m = re.search(r"(\d+\.\d+(?:\.\d+)?)", first_line)
        return m.group(1) if m else first_line.strip()
    except Exception:
        return "unknown"


def detect_python_version() -> str:
    return f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}"


def detect_python_jit() -> bool:
    """Check whether Python supports JIT compilation."""
    try:
        if hasattr(sys, "_jit"):
            return bool(sys._jit.is_available())
    except Exception:
        pass
    return False


def detect_perf() -> bool:
    """Check if perf stat works with user-space counters."""
    try:
        result = subprocess.run(
            ["perf", "stat", "-e", "instructions:u", "-x", ",", "--", "true"],
            capture_output=True, text=True, timeout=5,
        )
        return result.returncode == 0
    except Exception:
        return False


def detect_kernel() -> str:
    return platform.release()


def detect_cpu() -> str:
    try:
        with open("/proc/cpuinfo") as f:
            for line in f:
                if line.startswith("model name"):
                    return line.split(":", 1)[1].strip()
    except Exception:
        pass
    return platform.processor() or "unknown"


# ── Benchmark discovery ──────────────────────────────────────────────

def discover_benchmarks(programs_dir: Path, filter_pat: str = "") -> list[dict]:
    """Find .pb files and their matching .py counterparts."""
    benchmarks = []
    gui_prefixes = ("gui_",)

    for pb_file in sorted(programs_dir.glob("*.pb")):
        name = pb_file.stem
        py_file = pb_file.with_suffix(".py")

        if not py_file.exists():
            print(f"  warning: no matching .py for {pb_file.name}, skipping",
                  file=sys.stderr)
            continue

        is_gui = any(name.startswith(p) for p in gui_prefixes)

        if filter_pat and filter_pat.lower() not in name.lower():
            continue

        benchmarks.append({
            "name": name,
            "pb": pb_file,
            "py": py_file,
            "is_gui": is_gui,
        })

    return benchmarks


# ── Running benchmarks ───────────────────────────────────────────────

def parse_perf_csv(csv_path: str) -> PerfCounters:
    """Parse perf stat CSV output."""
    counters = PerfCounters()
    try:
        with open(csv_path) as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#"):
                    continue
                parts = line.split(",")
                if len(parts) < 3:
                    continue
                raw_value = parts[0].strip()
                event_name = parts[2].strip()
                if raw_value in ("<not counted>", "<not supported>", ""):
                    continue
                try:
                    value = int(raw_value)
                except ValueError:
                    continue
                if "instructions" in event_name:
                    counters.instructions = value
                elif "cycles" in event_name and counters.cycles is None:
                    counters.cycles = value
                elif "cache-misses" in event_name:
                    counters.cache_misses = value
                elif "branch-misses" in event_name:
                    counters.branch_misses = value
    except Exception:
        pass
    return counters


def run_single(
    cmd: list[str],
    use_perf: bool,
    timeout: float = 120.0,
    env: Optional[dict] = None,
    cwd: Optional[Path] = None,
) -> RunResult:
    """Run a single benchmark invocation, optionally with perf stat."""
    run_env = os.environ.copy()
    if env:
        run_env.update(env)

    if use_perf:
        with tempfile.NamedTemporaryFile(mode="w", suffix=".csv", delete=False) as tmp:
            perf_csv = tmp.name

        perf_cmd = [
            "perf", "stat",
            "-e", "instructions:u,cycles:u,cache-misses:u,branch-misses:u",
            "-x", ",",
            "-o", perf_csv,
            "--",
        ] + cmd

        start = time.perf_counter()
        try:
            result = subprocess.run(
                perf_cmd,
                capture_output=True, text=True, timeout=timeout,
                env=run_env, cwd=cwd,
            )
        except subprocess.TimeoutExpired:
            try:
                os.unlink(perf_csv)
            except OSError:
                pass
            return RunResult(wall_time=timeout, output="TIMEOUT")
        elapsed = time.perf_counter() - start

        perf_counters = parse_perf_csv(perf_csv)
        try:
            os.unlink(perf_csv)
        except OSError:
            pass

        output = result.stdout.strip()
        return RunResult(wall_time=elapsed, output=output, perf=perf_counters)
    else:
        start = time.perf_counter()
        try:
            result = subprocess.run(
                cmd,
                capture_output=True, text=True, timeout=timeout,
                env=run_env, cwd=cwd,
            )
        except subprocess.TimeoutExpired:
            return RunResult(wall_time=timeout, output="TIMEOUT")
        elapsed = time.perf_counter() - start
        output = result.stdout.strip()
        return RunResult(wall_time=elapsed, output=output)


def run_benchmark_set(
    cmd: list[str],
    num_runs: int,
    use_perf: bool,
    env: Optional[dict] = None,
    cwd: Optional[Path] = None,
) -> BenchmarkResult:
    """Run a benchmark multiple times and aggregate."""
    result = BenchmarkResult()
    for i in range(num_runs):
        do_perf = use_perf and (i == num_runs - 1)
        run = run_single(cmd, do_perf, env=env, cwd=cwd)
        result.runs.append(run)
    return result


# ── Formatting helpers ───────────────────────────────────────────────

def fmt_time(seconds: float) -> str:
    """Format a time value for display."""
    if seconds < 0.001:
        return f"{seconds * 1_000_000:.0f}µs"
    if seconds < 1.0:
        return f"{seconds * 1000:.1f}ms"
    if seconds < 10.0:
        return f"{seconds:.3f}s"
    return f"{seconds:.1f}s"


def fmt_count(n: Optional[int]) -> str:
    """Format a large number with SI suffixes."""
    if n is None:
        return "─"
    if n >= 1_000_000_000:
        return f"{n / 1_000_000_000:.1f}B"
    if n >= 1_000_000:
        return f"{n / 1_000_000:.1f}M"
    if n >= 1_000:
        return f"{n / 1_000:.1f}K"
    return str(n)


def fmt_speedup(pb_time: float, other_time: float, style: Style) -> str:
    """Format a speedup ratio with colour (Pogberry relative to other)."""
    if pb_time <= 0 or other_time <= 0:
        return "─"
    ratio = other_time / pb_time
    text = f"{ratio:.1f}x"
    if ratio >= 1.05:
        return style.green(f"{text} ✓")
    elif ratio <= 0.95:
        return style.red(f"{text} ✗")
    else:
        return style.yellow(f"{text} ≈")


def fmt_ipc(val: Optional[float]) -> str:
    if val is None:
        return "─"
    return f"{val:.2f}"


def fmt_msframe(seconds: float, frames: int) -> str:
    """Format as ms/frame."""
    ms = (seconds / frames) * 1000
    return f"{ms:.1f}ms/fr"


# ── Output rendering ────────────────────────────────────────────────

def print_header(style: Style, gcc_ver: str, py_ver: str, has_jit: bool,
                 kernel: str, cpu: str, num_runs: int, has_perf: bool) -> None:
    """Print the suite header."""
    w = 90
    print()
    print(style.bold(style.cyan("┌" + "─" * (w - 2) + "┐")))
    title = "🍇  Pogberry Benchmark Suite"
    pad = (w - 4 - len(title)) // 2
    print(style.bold(style.cyan("│")) + " " * pad + style.bold(title) +
          " " * (w - 3 - pad - len(title)) + style.bold(style.cyan("│")))

    jit_label = " (JIT available)" if has_jit else ""
    info = f"gcc {gcc_ver} · Python {py_ver}{jit_label} · Linux {kernel}"
    pad = (w - 4 - len(info)) // 2
    print(style.bold(style.cyan("│")) + " " * pad + style.dim(info) +
          " " * (w - 3 - pad - len(info)) + style.bold(style.cyan("│")))

    cpu_short = cpu[:w - 6] if len(cpu) > w - 6 else cpu
    pad = (w - 4 - len(cpu_short)) // 2
    print(style.bold(style.cyan("│")) + " " * pad + style.dim(cpu_short) +
          " " * (w - 3 - pad - len(cpu_short)) + style.bold(style.cyan("│")))

    run_info = f"{num_runs} runs per benchmark · median times"
    if has_perf:
        run_info += " · perf counters"
    pad = (w - 4 - len(run_info)) // 2
    print(style.bold(style.cyan("│")) + " " * pad + style.dim(run_info) +
          " " * (w - 3 - pad - len(run_info)) + style.bold(style.cyan("│")))

    print(style.bold(style.cyan("├" + "─" * (w - 2) + "┤")))
    print(style.bold(style.cyan("│")) + " " * (w - 2) + style.bold(style.cyan("│")))


def print_timing_table(entries: list[BenchmarkEntry], style: Style,
                       has_jit: bool, verbose: bool) -> None:
    """Print the main timing comparison table."""
    w = 90
    col_bench = 22
    col_num = 10

    # Header row
    if has_jit:
        hdr = (f"  {pad_vis('BENCHMARK', col_bench)}"
               f"{pad_vis('POGBERRY', col_num, 'right')}  "
               f"{pad_vis('PYTHON', col_num, 'right')}  "
               f"{pad_vis('PY+JIT', col_num, 'right')}  "
               f"{pad_vis('vs PY', col_num, 'center')}  "
               f"{pad_vis('vs JIT', col_num, 'center')}")
        sep = f"  {'─' * col_bench}{'─' * col_num}  {'─' * col_num}  {'─' * col_num}  {'─' * col_num}  {'─' * col_num}"
    else:
        hdr = (f"  {pad_vis('BENCHMARK', col_bench)}"
               f"{pad_vis('POGBERRY', col_num, 'right')}  "
               f"{pad_vis('PYTHON', col_num, 'right')}  "
               f"{pad_vis('vs PY', col_num, 'center')}")
        sep = f"  {'─' * col_bench}{'─' * col_num}  {'─' * col_num}  {'─' * col_num}"

    print(pad_box_row(style.bold(hdr), w, style))
    print(pad_box_row(style.dim(sep), w, style))

    # Separate pure and GUI entries
    pure_entries = [e for e in entries if not e.is_gui]
    gui_entries = [e for e in entries if e.is_gui]

    def print_entry(e: BenchmarkEntry) -> None:
        if e.error:
            error_line = f"  {pad_vis(e.name, col_bench)}{style.red(e.error)}"
            print(pad_box_row(error_line, w, style))
            return

        pb_time = e.pogberry.median if e.pogberry else 0
        py_time = e.python.median if e.python else 0
        jit_time = e.python_jit.median if e.python_jit else 0

        if e.is_gui:
            frames = 300 if "stress" in e.name else 500
            pb_str = fmt_msframe(pb_time, frames) if pb_time else "─"
            py_str = fmt_msframe(py_time, frames) if py_time else "─"
        else:
            pb_str = fmt_time(pb_time) if pb_time else "─"
            py_str = fmt_time(py_time) if py_time else "─"

        vs_py = fmt_speedup(pb_time, py_time, style) if (pb_time and py_time) else "─"

        if has_jit and not e.is_gui:
            jit_str = fmt_time(jit_time) if jit_time else "─"
            vs_jit = fmt_speedup(pb_time, jit_time, style) if (pb_time and jit_time) else "─"
            line = (f"  {pad_vis(e.name, col_bench)}"
                    f"{pad_vis(pb_str, col_num, 'right')}  "
                    f"{pad_vis(py_str, col_num, 'right')}  "
                    f"{pad_vis(jit_str, col_num, 'right')}  "
                    f"{pad_vis(vs_py, col_num, 'center')}  "
                    f"{pad_vis(vs_jit, col_num, 'center')}")
        elif has_jit and e.is_gui:
            line = (f"  {pad_vis(e.name, col_bench)}"
                    f"{pad_vis(pb_str, col_num, 'right')}  "
                    f"{pad_vis(py_str, col_num, 'right')}  "
                    f"{pad_vis('─', col_num, 'center')}  "
                    f"{pad_vis(vs_py, col_num, 'center')}  "
                    f"{pad_vis('─', col_num, 'center')}")
        else:
            line = (f"  {pad_vis(e.name, col_bench)}"
                    f"{pad_vis(pb_str, col_num, 'right')}  "
                    f"{pad_vis(py_str, col_num, 'right')}  "
                    f"{pad_vis(vs_py, col_num, 'center')}")

        if not e.correct:
            line += style.red(" ⚠")

        print(pad_box_row(line, w, style))

        if verbose and e.pogberry and len(e.pogberry.times) >= 2:
            detail = (f"     pb: min={fmt_time(e.pogberry.best)} "
                      f"max={fmt_time(e.pogberry.worst)} "
                      f"σ={fmt_time(e.pogberry.stdev)}")
            print(pad_box_row(style.dim(detail), w, style))

    for e in pure_entries:
        print_entry(e)

    # Geometric mean for pure benchmarks
    pb_times = [e.pogberry.median for e in pure_entries if e.pogberry and e.pogberry.median > 0]
    py_times = [e.python.median for e in pure_entries if e.python and e.python.median > 0]

    if pb_times and py_times and len(pb_times) == len(py_times):
        print(pad_box_row("", w, style))

        geo_pb = math.exp(sum(math.log(t) for t in pb_times) / len(pb_times))
        geo_py = math.exp(sum(math.log(t) for t in py_times) / len(py_times))
        vs_geo_py = fmt_speedup(geo_pb, geo_py, style)

        if has_jit:
            jit_times = [e.python_jit.median for e in pure_entries
                         if e.python_jit and e.python_jit.median > 0]
            if len(jit_times) == len(pb_times):
                geo_jit = math.exp(sum(math.log(t) for t in jit_times) / len(jit_times))
                vs_geo_jit = fmt_speedup(geo_pb, geo_jit, style)
                line = (f"  {pad_vis(style.bold('GEOMETRIC MEAN'), col_bench)}"
                        f"{pad_vis(fmt_time(geo_pb), col_num, 'right')}  "
                        f"{pad_vis(fmt_time(geo_py), col_num, 'right')}  "
                        f"{pad_vis(fmt_time(geo_jit), col_num, 'right')}  "
                        f"{pad_vis(vs_geo_py, col_num, 'center')}  "
                        f"{pad_vis(vs_geo_jit, col_num, 'center')}")
            else:
                line = (f"  {pad_vis(style.bold('GEOMETRIC MEAN'), col_bench)}"
                        f"{pad_vis(fmt_time(geo_pb), col_num, 'right')}  "
                        f"{pad_vis(fmt_time(geo_py), col_num, 'right')}  "
                        f"{pad_vis('─', col_num, 'center')}  "
                        f"{pad_vis(vs_geo_py, col_num, 'center')}  "
                        f"{pad_vis('─', col_num, 'center')}")
        else:
            line = (f"  {pad_vis(style.bold('GEOMETRIC MEAN'), col_bench)}"
                    f"{pad_vis(fmt_time(geo_pb), col_num, 'right')}  "
                    f"{pad_vis(fmt_time(geo_py), col_num, 'right')}  "
                    f"{pad_vis(vs_geo_py, col_num, 'center')}")

        print(pad_box_row(line, w, style))

    # GUI section
    if gui_entries:
        print(pad_box_row("", w, style))
        gui_label = "  ── GUI BENCHMARKS (pb_gui/Raylib vs pygame) "
        gui_label += "─" * max(0, 84 - len(gui_label))
        print(pad_box_row(style.bold(gui_label), w, style))
        print(pad_box_row("", w, style))
        for e in gui_entries:
            print_entry(e)

    print(pad_box_row("", w, style))
    print(style.bold(style.cyan("└" + "─" * (w - 2) + "┘")))


def print_perf_table(entries: list[BenchmarkEntry], style: Style) -> None:
    """Print the hardware counters table."""
    has_any = any(
        (e.pogberry and e.pogberry.last_perf and e.pogberry.last_perf.instructions)
        or (e.python and e.python.last_perf and e.python.last_perf.instructions)
        for e in entries
    )
    if not has_any:
        return

    w = 90
    print()
    print(style.bold(style.cyan("┌" + "─" * (w - 2) + "┐")))
    title = "⚡ Hardware Performance Counters (via perf stat)"
    pad = (w - 4 - len(title)) // 2
    print(style.bold(style.cyan("│")) + " " * pad + style.bold(title) +
          " " * (w - 3 - pad - len(title)) + style.bold(style.cyan("│")))
    print(style.bold(style.cyan("├" + "─" * (w - 2) + "┤")))

    col_bench = 18
    hdr = (f"  {pad_vis('BENCHMARK', col_bench)} "
           f"{pad_vis('RT', 3, 'right')}  "
           f"{pad_vis('TIME', 8, 'right')}  "
           f"{pad_vis('INSTRS', 10, 'right')}  "
           f"{pad_vis('CYCLES', 10, 'right')}  "
           f"{pad_vis('IPC', 5, 'right')}  "
           f"{pad_vis('CACHE$', 8, 'right')}  "
           f"{pad_vis('BR MISS', 8, 'right')}")
    print(pad_box_row(style.bold(hdr), w, style))
    sep = f"  {'─' * col_bench} {'─' * 3}  {'─' * 8}  {'─' * 10}  {'─' * 10}  {'─' * 5}  {'─' * 8}  {'─' * 8}"
    print(pad_box_row(style.dim(sep), w, style))

    for e in entries:
        if e.is_gui:
            continue
        for label, result in [("pb", e.pogberry), ("py", e.python)]:
            if not result or not result.last_perf:
                continue
            p = result.last_perf
            line = (f"  {pad_vis(e.name, col_bench)} "
                    f"{pad_vis(label, 3, 'right')}  "
                    f"{pad_vis(fmt_time(result.median), 8, 'right')}  "
                    f"{pad_vis(fmt_count(p.instructions), 10, 'right')}  "
                    f"{pad_vis(fmt_count(p.cycles), 10, 'right')}  "
                    f"{pad_vis(fmt_ipc(p.ipc), 5, 'right')}  "
                    f"{pad_vis(fmt_count(p.cache_misses), 8, 'right')}  "
                    f"{pad_vis(fmt_count(p.branch_misses), 8, 'right')}")
            print(pad_box_row(line, w, style))

    print(pad_box_row("", w, style))
    print(style.bold(style.cyan("└" + "─" * (w - 2) + "┘")))


# ── Progress display ─────────────────────────────────────────────────

class ProgressPrinter:
    """Prints progress during benchmark execution."""

    def __init__(self, style: Style, total: int) -> None:
        self.style = style
        self.total = total
        self.current = 0
        self.is_tty = sys.stdout.isatty()

    def start(self, name: str, runtime: str, run_num: int, total_runs: int) -> None:
        if self.is_tty:
            bar = f"[{self.current + 1}/{self.total}]"
            msg = f"\r  {self.style.dim(bar)} {name} ({runtime}) run {run_num}/{total_runs}..."
            print(msg, end="", flush=True)

    def finish_benchmark(self, name: str, pb_time: float, py_time: float) -> None:
        self.current += 1
        if self.is_tty:
            print("\r" + " " * 80 + "\r", end="", flush=True)
        ratio = py_time / pb_time if pb_time > 0 else 0
        check = self.style.green("✓") if ratio >= 1.0 else self.style.red("✗")
        print(f"  {check} {name:<22} pb={fmt_time(pb_time):<10} "
              f"py={fmt_time(py_time):<10} ({ratio:.1f}x)")

    def finish_benchmark_error(self, name: str, error: str) -> None:
        self.current += 1
        if self.is_tty:
            print("\r" + " " * 80 + "\r", end="", flush=True)
        print(f"  {self.style.red('✗')} {name:<22} {self.style.red(error)}")


# ── Main logic ───────────────────────────────────────────────────────

def check_gui_available(project_root: Path) -> bool:
    """Check if pb_gui (Raylib backend) is available."""
    raylib_paths = [
        project_root / "lib" / "pb_raylib_linux.so",
        project_root / "build" / "pb_raylib_linux.so",
    ]
    return any(p.exists() for p in raylib_paths)


def check_pygame_available() -> bool:
    """Check if pygame is importable."""
    try:
        result = subprocess.run(
            [sys.executable, "-c",
             "import os; os.environ['PYGAME_HIDE_SUPPORT_PROMPT']='1'; import pygame"],
            capture_output=True, timeout=10,
        )
        return result.returncode == 0
    except Exception:
        return False


def find_binary(args_binary: Optional[Path], project_root: Path) -> Path:
    """Find the Pogberry binary to use."""
    if args_binary:
        return args_binary.resolve()

    release = project_root / "build" / "release" / "pb"
    if release.is_file():
        return release

    debug = project_root / "build" / "pb"
    if debug.is_file():
        return debug

    print("error: no pb binary found. Run `make` or `make release` first.",
          file=sys.stderr)
    sys.exit(2)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Pogberry benchmark suite.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument("--binary", type=Path,
                        help="path to the pb executable")
    parser.add_argument("--runs", type=int, default=5,
                        help="number of runs per benchmark")
    parser.add_argument("--filter", type=str, default="",
                        help="only run benchmarks matching this pattern")
    parser.add_argument("--gui", dest="gui", action="store_true", default=None,
                        help="include GUI benchmarks")
    parser.add_argument("--no-gui", dest="gui", action="store_false",
                        help="exclude GUI benchmarks")
    parser.add_argument("--headless", action="store_true",
                        help="run GUI benchmarks with virtual display")
    parser.add_argument("--perf", dest="perf", action="store_true", default=None,
                        help="enable perf stat collection")
    parser.add_argument("--no-perf", dest="perf", action="store_false",
                        help="disable perf stat collection")
    parser.add_argument("--build", action="store_true",
                        help="run `make release` before benchmarking")
    parser.add_argument("--json", action="store_true",
                        help="output machine-readable JSON")
    parser.add_argument("--verbose", action="store_true",
                        help="show min/max/stddev per benchmark")
    parser.add_argument("--no-color", action="store_true",
                        help="disable ANSI colours")
    args = parser.parse_args()

    # Resolve paths
    runner_dir = Path(__file__).resolve().parent
    project_root = runner_dir.parent
    programs_dir = runner_dir / "programs"

    color_enabled = (not args.no_color
                     and "NO_COLOR" not in os.environ
                     and sys.stdout.isatty())
    style = Style(color_enabled)

    # Build if requested
    if args.build:
        print(style.bold("Building release binary..."))
        result = subprocess.run(["make", "release"], cwd=project_root,
                                capture_output=True, text=True)
        if result.returncode != 0:
            print(style.red("Build failed:"))
            print(result.stderr)
            return 2

    # Find binary
    binary = find_binary(args.binary, project_root)
    try:
        binary_label = binary.relative_to(project_root)
    except ValueError:
        binary_label = binary

    # Detect environment
    gcc_ver = detect_gcc_version()
    py_ver = detect_python_version()
    has_jit = detect_python_jit()
    kernel = detect_kernel()
    cpu = detect_cpu()

    # Detect perf
    if args.perf is None:
        use_perf = detect_perf()
    else:
        use_perf = args.perf

    # Detect GUI availability
    gui_pb_ok = check_gui_available(project_root)
    gui_py_ok = check_pygame_available()
    gui_available = gui_pb_ok and gui_py_ok

    if args.gui is None:
        include_gui = gui_available
    elif args.gui is True:
        if not gui_available:
            missing = []
            if not gui_pb_ok:
                missing.append("Raylib backend (lib/pb_raylib_linux.so)")
            if not gui_py_ok:
                missing.append("pygame")
            print(f"warning: GUI benchmarks requested but missing: {', '.join(missing)}",
                  file=sys.stderr)
        include_gui = gui_available
    else:
        include_gui = False

    # Discover benchmarks
    all_benchmarks = discover_benchmarks(programs_dir, args.filter)

    if include_gui:
        benchmarks = [b for b in all_benchmarks if not b["is_gui"] or gui_available]
    else:
        benchmarks = [b for b in all_benchmarks if not b["is_gui"]]

    if not benchmarks:
        print("error: no benchmarks found", file=sys.stderr)
        return 2

    # Print header info
    print()
    print(style.bold("Pogberry benchmark suite"))
    print(f"  binary   {binary_label}")
    print(f"  python   {sys.executable} ({py_ver}{' · JIT available' if has_jit else ''})")
    print(f"  runs     {args.runs}")
    print(f"  perf     {'enabled' if use_perf else 'disabled'}")
    gui_count = sum(1 for b in benchmarks if b["is_gui"])
    pure_count = len(benchmarks) - gui_count
    print(f"  tests    {pure_count} pure + {gui_count} GUI")
    print()

    # Prepare GUI env
    gui_env = {}
    if args.headless:
        gui_env["SDL_VIDEODRIVER"] = "dummy"

    # Environments for Python runs
    py_nojit_env = {"PYTHON_JIT": "0"}
    py_jit_env = {"PYTHON_JIT": "1"}

    # Run benchmarks
    total_benches = len(benchmarks)
    progress = ProgressPrinter(style, total_benches)
    entries: list[BenchmarkEntry] = []

    for bench in benchmarks:
        name = bench["name"]
        pb_file = bench["pb"]
        py_file = bench["py"]
        is_gui = bench["is_gui"]
        entry = BenchmarkEntry(name=name, is_gui=is_gui)

        try:
            # Run Pogberry
            pb_cmd = [str(binary), str(pb_file)]
            pb_env = gui_env if is_gui else None
            for i in range(args.runs):
                progress.start(name, "pogberry", i + 1, args.runs)
            entry.pogberry = run_benchmark_set(
                pb_cmd, args.runs, use_perf, env=pb_env, cwd=project_root
            )

            # Run Python (no JIT)
            py_cmd_nojit = [sys.executable]
            if has_jit:
                py_cmd_nojit += ["-X", "jit=off"]
            py_cmd_nojit.append(str(py_file))
            for i in range(args.runs):
                progress.start(name, "python", i + 1, args.runs)
            
            env_for_nojit = {**py_nojit_env, **gui_env} if is_gui else py_nojit_env
            entry.python = run_benchmark_set(
                py_cmd_nojit, args.runs, use_perf, env=env_for_nojit
            )

            # Run Python with JIT (only for pure benchmarks)
            if has_jit and not is_gui:
                py_cmd_jit = [sys.executable, "-X", "jit", str(py_file)]
                for i in range(args.runs):
                    progress.start(name, "python+jit", i + 1, args.runs)
                entry.python_jit = run_benchmark_set(
                    py_cmd_jit, args.runs, use_perf, env=py_jit_env
                )

            # Correctness check: compare pb and py output
            if entry.pogberry and entry.python:
                pb_out = entry.pogberry.output.strip()
                py_out = entry.python.output.strip()
                if pb_out != py_out:
                    entry.correct = False
                    entry.error = f"output mismatch: pb={pb_out!r} py={py_out!r}"

            pb_med = entry.pogberry.median if entry.pogberry else 0
            py_med = entry.python.median if entry.python else 0
            progress.finish_benchmark(name, pb_med, py_med)

        except Exception as exc:
            entry.error = str(exc)
            progress.finish_benchmark_error(name, str(exc))

        entries.append(entry)

    # Print results
    print()
    print_header(style, gcc_ver, py_ver, has_jit, kernel, cpu,
                 args.runs, use_perf)
    print_timing_table(entries, style, has_jit, args.verbose)

    if use_perf:
        print_perf_table(entries, style)

    # JSON output
    if args.json:
        json_data = {
            "meta": {
                "gcc": gcc_ver,
                "python": py_ver,
                "jit": has_jit,
                "kernel": kernel,
                "cpu": cpu,
                "runs": args.runs,
                "binary": str(binary),
            },
            "benchmarks": [],
        }
        for e in entries:
            bench_data: dict = {
                "name": e.name,
                "is_gui": e.is_gui,
                "correct": e.correct,
            }
            for label, result in [("pogberry", e.pogberry),
                                   ("python", e.python),
                                   ("python_jit", e.python_jit)]:
                if result:
                    d: dict = {
                        "median": result.median,
                        "mean": result.mean,
                        "stdev": result.stdev,
                        "min": result.best,
                        "max": result.worst,
                        "times": result.times,
                    }
                    if result.last_perf:
                        p = result.last_perf
                        d["perf"] = {
                            "instructions": p.instructions,
                            "cycles": p.cycles,
                            "ipc": p.ipc,
                            "cache_misses": p.cache_misses,
                            "branch_misses": p.branch_misses,
                        }
                    bench_data[label] = d
            json_data["benchmarks"].append(bench_data)

        json_path = Path(__file__).resolve().parent / "results.json"
        json_path.write_text(json.dumps(json_data, indent=2) + "\n")
        print(f"\n  JSON results written to {json_path}")

    print()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
