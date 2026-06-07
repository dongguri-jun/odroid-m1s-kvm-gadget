# Learnings

## 2026-06-07 Task: schedule-system-start

- TinyPilot defaults to `KEYBOARD_PATH=/dev/hidg0` and `MOUSE_PATH=/dev/hidg1`.
- TinyPilot keyboard writes are 8-byte boot keyboard reports.
- TinyPilot mouse writes are 7-byte absolute mouse reports: buttons, X low/high, Y low/high, vertical wheel, horizontal wheel.
- TinyPilot's own gadget setup uses `functions/hid.keyboard` and `functions/hid.mouse`, with keyboard `report_length=8` and mouse `report_length=7`.
- Safe configfs teardown must unbind `UDC` before removing symlinks and function directories.

## 2026-06-07 Task: t1-hid-gadget-design

- TinyPilot's init script uses a Linux Foundation multifunction gadget identity by default: `idVendor=0x1d6b`, `idProduct=0x0104`.
- TinyPilot keyboard descriptor is compatible with an 8-byte keyboard report: modifier, reserved byte, then up to six keycodes.
- TinyPilot mouse descriptor uses absolute X/Y coordinates from 0 to 32767 plus vertical and horizontal wheel bytes.
- Runtime UDC name must be discovered from `/sys/class/udc`; static DTB evidence is not enough to hardcode a bind target.
