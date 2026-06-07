#!/usr/bin/env bash
set -euo pipefail

KEYBOARD_PATH="${1:-/dev/hidg0}"

if [[ ! -w "$KEYBOARD_PATH" ]]; then
  printf 'ERROR: keyboard HID path is not writable: %s\n' "$KEYBOARD_PATH" >&2
  exit 1
fi

# TinyPilot-compatible 8-byte keyboard report:
# byte 0 modifier, byte 1 reserved, byte 2 keycode.
# HID keycode 0x04 is lowercase 'a' without modifiers.
printf '\x00\x00\x04\x00\x00\x00\x00\x00' > "$KEYBOARD_PATH"

# Release all keys with another exact 8-byte report.
printf '\x00\x00\x00\x00\x00\x00\x00\x00' > "$KEYBOARD_PATH"
