# Issues

## 2026-06-07 Task: schedule-system-start

- ODROID Ubuntu 24.04 server image `20250522` is a userspace base only; its stock kernel lacks configfs HID gadget support.
- Real-device validation is still pending for `/sys/class/udc`, UDC bind, `/dev/hidg0`, `/dev/hidg1`, target PC enumeration, and BIOS/UEFI keyboard input.
- TinyPilot uses a 7-byte absolute mouse report, so a generic 4-byte boot mouse descriptor is not the default compatibility path.
- No HDMI capture dongle has been verified yet for this project.
