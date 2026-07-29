#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
TEST_DIR="$SCRIPT_DIR"
PGBIN="$ROOT_DIR/build/pogberry"

if [[ $# -gt 0 && -n "$1" ]]; then
    TEST_DIR="$TEST_DIR/$1"
fi

if [[ ! -x "$PGBIN" ]]; then
    echo "Test binary not found: $PGBIN"
    exit 2
fi

if [[ ! -d "$TEST_DIR" ]]; then
    echo "Test directory not found: $TEST_DIR"
    exit 2
fi

ACTUAL="$(mktemp)"
trap 'rm -f "$ACTUAL"' EXIT

PASS=0
FAIL=0

run_test() {
    local source="$1"
    local expected="${source%.pb}.out"
    local status_file="${source%.pb}.status"
    local expected_status=0
    local actual_status
    local relative

    relative="${source#"$TEST_DIR"/}"

    if [[ ! -f "$expected" ]]; then
        echo "[FAIL] $relative"
        echo "  Missing expected-output file: $expected"
        ((FAIL++))
        return
    fi

    if [[ -f "$status_file" ]]; then
        expected_status="$(tr -d '[:space:]' < "$status_file")"
    fi

    "$PGBIN" "$source" > "$ACTUAL" 2>&1
    actual_status=$?

    if cmp -s "$ACTUAL" "$expected" &&
       [[ "$actual_status" == "$expected_status" ]]; then
        echo "[PASS] $relative"
        ((PASS++))
        return
    fi

    echo "[FAIL] $relative"
    echo "  Expected exit code: $expected_status"
    echo "  Actual exit code:   $actual_status"
    echo "  Output diff:"
    diff -u "$expected" "$ACTUAL" || true
    ((FAIL++))
}

while IFS= read -r source; do
    run_test "$source"
done < <(find "$TEST_DIR" -type f -name '*.pb' -print | sort)

echo
echo "Passed: $PASS, Failed: $FAIL"

[[ "$FAIL" -eq 0 ]]