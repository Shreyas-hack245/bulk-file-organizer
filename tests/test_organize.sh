#!/usr/bin/env bash
#
# test_organize.sh — Minimal smoke tests for organize.sh (no external
# test framework required — pure bash with plain assertions).
#
# Usage: ./tests/test_organize.sh

set -euo pipefail

TEST_DIR="$(mktemp -d)"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." &>/dev/null && pwd)"
ORGANIZE="${SCRIPT_DIR}/organize.sh"
FAILURES=0

cleanup() {
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT

assert() {
    local desc="$1"
    local condition="$2"
    if eval "$condition"; then
        echo "  PASS: $desc"
    else
        echo "  FAIL: $desc"
        FAILURES=$((FAILURES + 1))
    fi
}

echo "Setting up test fixtures in $TEST_DIR"
touch "$TEST_DIR/photo.jpg"
touch "$TEST_DIR/report.pdf"
touch "$TEST_DIR/song.mp3"
touch "$TEST_DIR/archive.zip"
touch "$TEST_DIR/notes.xyz"   # unknown extension -> Others

echo "Running organize.sh (real run)..."
"$ORGANIZE" -s "$TEST_DIR" -l "$TEST_DIR/test.log" > /dev/null

echo "Checking results:"
assert "photo.jpg moved to Images/"   "[[ -f '$TEST_DIR/Images/photo.jpg' ]]"
assert "report.pdf moved to Documents/" "[[ -f '$TEST_DIR/Documents/report.pdf' ]]"
assert "song.mp3 moved to Audio/"     "[[ -f '$TEST_DIR/Audio/song.mp3' ]]"
assert "archive.zip moved to Archives/" "[[ -f '$TEST_DIR/Archives/archive.zip' ]]"
assert "notes.xyz moved to Others/"   "[[ -f '$TEST_DIR/Others/notes.xyz' ]]"
assert "log file was created"         "[[ -f '$TEST_DIR/test.log' ]]"

echo "Testing collision handling..."
touch "$TEST_DIR/dup.txt"
mkdir -p "$TEST_DIR/Documents"
touch "$TEST_DIR/Documents/dup.txt"
"$ORGANIZE" -s "$TEST_DIR" -l "$TEST_DIR/test.log" > /dev/null
assert "colliding file renamed with (1) suffix" "[[ -f '$TEST_DIR/Documents/dup (1).txt' ]]"

echo "Testing dry-run mode (no files should move)..."
touch "$TEST_DIR/untouched.png"
"$ORGANIZE" -s "$TEST_DIR" -l "$TEST_DIR/test.log" -n > /dev/null
assert "dry-run leaves file in place" "[[ -f '$TEST_DIR/untouched.png' ]]"
assert "dry-run does not create destination" "[[ ! -f '$TEST_DIR/Images/untouched.png' ]]"

echo ""
if [[ "$FAILURES" -eq 0 ]]; then
    echo "All tests passed."
    exit 0
else
    echo "$FAILURES test(s) failed."
    exit 1
fi