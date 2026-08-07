# Pogberry tests

`make test` is the single entry point for the complete test suite. It builds the interpreter when needed, then runs every `.pb` file below `cases/`.

Useful commands:

```sh
make test
make test TEST_PATH=collections/lists
make test TEST_PATH=algorithms TEST_ARGS="--verbose"
make test TEST_ARGS="--fail-fast --jobs 1"
python tests/runner/run_tests.py --list
```

Selectors are case-insensitive path fragments. Multiple selectors run the union of their matches. Tests run in parallel by default, but their results are always reported in path order.

Every test is a normal Pogberry source file with its contract embedded at the end:

```pogberry
print(2 + 2);
// EXPECTED STATUS: 0
// EXPECTED OUTPUT:
//|4
// END EXPECTED OUTPUT
```

The status defaults to `0` when omitted. Keep the status line explicit for error tests. Every output line begins with `//|`; an empty block means the program must produce no output. Output and exit status are checked exactly. Each process has a five-second timeout unless `--timeout` changes it.

The directories describe behavior rather than implementation details:

- `language/` covers syntax and core execution semantics.
- `collections/` covers lists, maps, strings, and indexing.
- `standard-library/` covers globally available native functions.
- `algorithms/` keeps realistic programs that exercise multiple features.
- `integration/` combines broad areas of the language.
- `errors/` locks down compile-time and runtime failures.
- `regressions/` preserves focused tests for previously broken behavior.

New fixes and features should normally add at least one success case and one relevant failure case. Prefer focused fixtures; use integration tests only when the interaction between features is what matters.
