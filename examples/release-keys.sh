#!/usr/bin/env bash
set -euo pipefail

KEYBOARD_PATH="${1:-/dev/hidg0}"

if [[ ! -w "$KEYBOARD_PATH" ]]; then
  printf 'ERROR: keyboard HID path is not writable: %s\n' "$KEYBOARD_PATH" >&2
  exit 1
fi

# Release all keyboard keys with an exact 8-byte zero report.
printf '\x00\x00\x00\x00\x00\x00\x00\x00' > "$KEYBOARD_PATH"
