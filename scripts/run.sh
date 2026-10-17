#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ "$project_dir" == /workspace/* ]]; then
  export XDG_DATA_HOME="${XDG_DATA_HOME:-/workspace/.tidebound/data}"
  export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-/workspace/.tidebound/config}"
  export XDG_CACHE_HOME="${XDG_CACHE_HOME:-/workspace/.tidebound/cache}"
  mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
fi
exec godot --path "$project_dir" "$@"
