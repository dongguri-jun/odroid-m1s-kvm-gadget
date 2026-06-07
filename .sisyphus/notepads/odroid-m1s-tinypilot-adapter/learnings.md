# Learnings

## 2026-06-07 Task: schedule-system-start

- TinyPilot defaults to `KEYBOARD_PATH=/dev/hidg0` and `MOUSE_PATH=/dev/hidg1`.
- TinyPilot keyboard writes are 8-byte boot keyboard reports.
- TinyPilot mouse writes are 7-byte absolute mouse reports: buttons, X low/high, Y low/high, vertical wheel, horizontal wheel.
- TinyPilot's own gadget setup uses `functions/hid.keyboard` and `functions/hid.mouse`, with keyboard `report_length=8` and mouse `report_length=7`.
- Safe configfs teardown must unbind `UDC` before removing symlinks and function directories.
