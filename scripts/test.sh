#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
test_home="$(mktemp -d /tmp/tidebound-test.XXXXXX)"
trap 'rm -rf -- "$test_home"' EXIT
mkdir -p "$test_home/data" "$test_home/config" "$test_home/cache"
XDG_DATA_HOME="$test_home/data" XDG_CONFIG_HOME="$test_home/config" XDG_CACHE_HOME="$test_home/cache" timeout 30s godot --headless --path "$project_dir" --script res://tests/smoke.gd

# UI tests use another isolated directory so the new-game confirmation is deterministic.
mkdir -p "$test_home/ui-data"
XDG_DATA_HOME="$test_home/ui-data" XDG_CONFIG_HOME="$test_home/config" XDG_CACHE_HOME="$test_home/cache" timeout 30s godot --headless --path "$project_dir" --script res://tests/interface.gd
