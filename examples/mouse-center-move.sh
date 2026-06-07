#!/usr/bin/env bash
set -euo pipefail

MOUSE_PATH="${1:-/dev/hidg1}"

if [[ ! -w "$MOUSE_PATH" ]]; then
  printf 'ERROR: mouse HID path is not writable: %s\n' "$MOUSE_PATH" >&2
  exit 1
fi

# Move pointer to center without pressing any button.
# TinyPilot-compatible 7-byte absolute mouse report.
printf '\x00\xff\x3f\xff\x3f\x00\x00' > "$MOUSE_PATH"
