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

mkdir -p "$test_home/catalog-data"
XDG_DATA_HOME="$test_home/catalog-data" XDG_CONFIG_HOME="$test_home/config" XDG_CACHE_HOME="$test_home/cache" timeout 30s godot --headless --path "$project_dir" --script res://tests/catalog.gd
mkdir -p "$test_home/species-data"
XDG_DATA_HOME="$test_home/species-data" XDG_CONFIG_HOME="$test_home/config" XDG_CACHE_HOME="$test_home/cache" timeout 30s godot --headless --path "$project_dir" --script res://tests/species.gd
mkdir -p "$test_home/elements-data"
XDG_DATA_HOME="$test_home/elements-data" XDG_CONFIG_HOME="$test_home/config" XDG_CACHE_HOME="$test_home/cache" timeout 30s godot --headless --path "$project_dir" --script res://tests/elements.gd
mkdir -p "$test_home/story-data"
XDG_DATA_HOME="$test_home/story-data" XDG_CONFIG_HOME="$test_home/config" XDG_CACHE_HOME="$test_home/cache" timeout 30s godot --headless --path "$project_dir" --script res://tests/story.gd
mkdir -p "$test_home/navigation-data"
XDG_DATA_HOME="$test_home/navigation-data" XDG_CONFIG_HOME="$test_home/config" XDG_CACHE_HOME="$test_home/cache" timeout 30s godot --headless --path "$project_dir" --script res://tests/navigation.gd
mkdir -p "$test_home/walk-data"
XDG_DATA_HOME="$test_home/walk-data" XDG_CONFIG_HOME="$test_home/config" XDG_CACHE_HOME="$test_home/cache" timeout 30s godot --headless --path "$project_dir" --script res://tests/world_walk.gd
XDG_DATA_HOME="$test_home/walk-data" XDG_CONFIG_HOME="$test_home/config" XDG_CACHE_HOME="$test_home/cache" timeout 30s godot --headless --path "$project_dir" --script res://tests/progression.gd
mkdir -p "$test_home/survey-data"
XDG_DATA_HOME="$test_home/survey-data" XDG_CONFIG_HOME="$test_home/config" XDG_CACHE_HOME="$test_home/cache" timeout 30s godot --headless --path "$project_dir" --script res://tests/surveys.gd
mkdir -p "$test_home/report-data"
XDG_DATA_HOME="$test_home/report-data" XDG_CONFIG_HOME="$test_home/config" XDG_CACHE_HOME="$test_home/cache" timeout 30s godot --headless --path "$project_dir" --script res://tests/battle_reports.gd
mkdir -p "$test_home/expanded-data"
XDG_DATA_HOME="$test_home/expanded-data" XDG_CONFIG_HOME="$test_home/config" XDG_CACHE_HOME="$test_home/cache" timeout 45s godot --headless --path "$project_dir" --script res://tests/expanded_world.gd
if [[ "${1:-}" == "--full" ]]; then
  mkdir -p "$test_home/campaign-data" "$test_home/collection-data"
  XDG_DATA_HOME="$test_home/campaign-data" XDG_CONFIG_HOME="$test_home/config" XDG_CACHE_HOME="$test_home/cache" timeout 180s godot --headless --path "$project_dir" --script res://tests/campaign.gd
  XDG_DATA_HOME="$test_home/collection-data" XDG_CONFIG_HOME="$test_home/config" XDG_CACHE_HOME="$test_home/cache" timeout 60s godot --headless --path "$project_dir" --script res://tests/collection.gd
fi

if [[ "${1:-}" == "--journey" ]]; then
  mkdir -p "$test_home/journey-data"
  XDG_DATA_HOME="$test_home/journey-data" XDG_CONFIG_HOME="$test_home/config" XDG_CACHE_HOME="$test_home/cache" timeout 360s godot --headless --path "$project_dir" --script res://tests/journey.gd
fi
