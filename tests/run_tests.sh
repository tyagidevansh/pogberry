#!/bin/bash
PGBIN=../pogberry
PASS=0
FAIL=0

for src in *.pb; do
    base=${src%.pb}
    expected="$base.out"
    output=$(mktemp)
    
    $PGBIN "$src" > "$output" 2>&1
    if diff -q "$output" "$expected" > /dev/null; then
        echo "[PASS] $src"
        ((PASS++))
    else
        echo "[FAIL] $src"
        echo "Expected:"
        cat "$expected"
        echo "Got:"
        cat "$output"
        ((FAIL++))
    fi
    rm "$output"
done

echo
echo "Passed: $PASS, Failed: $FAIL"
