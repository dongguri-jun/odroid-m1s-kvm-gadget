#!/usr/bin/env bash
set -euo pipefail

MOUSE_PATH="${1:-/dev/hidg1}"

if [[ ! -w "$MOUSE_PATH" ]]; then
  printf 'ERROR: mouse HID path is not writable: %s\n' "$MOUSE_PATH" >&2
  exit 1
fi

# TinyPilot-compatible 7-byte absolute mouse report:
# byte 0 buttons, byte 1-2 X little-endian, byte 3-4 Y little-endian,
# byte 5 vertical wheel, byte 6 horizontal wheel.
# Center is 16383 decimal = 0x3fff = ff 3f little-endian.
# Left-click at center.
printf '\x01\xff\x3f\xff\x3f\x00\x00' > "$MOUSE_PATH"

# Release at center.
printf '\x00\xff\x3f\xff\x3f\x00\x00' > "$MOUSE_PATH"
