# Decisions

## 2026-06-07 Task: schedule-system-start

- Active plan selected: `.sisyphus/plans/odroid-m1s-tinypilot-adapter.md`.
- Project direction is TinyPilot-compatible external adapter, not a new KVM UI.
- Phase 1 starts adapter-only: prove ODROID M1S can expose TinyPilot-compatible `/dev/hidg0`, `/dev/hidg1`, and V4L2/uStreamer interfaces before automating TinyPilot installation.
- Manual HID setup and teardown scripts come before systemd automation.
- Default mouse profile for TinyPilot compatibility is 7-byte absolute mouse, because TinyPilot writes 7-byte mouse reports to `/dev/hidg1`.

## 2026-06-07 Task: t1-hid-gadget-design

- Use one configfs composite gadget named `odroid_m1s_kvm` for the manual HID path.
- Create and link keyboard function `hid.usb0` before mouse function `hid.usb1` to preserve `/dev/hidg0` keyboard and `/dev/hidg1` mouse ordering.
- Keep setup manual until UDC binding, target-host enumeration, and safe teardown are verified on real ODROID M1S hardware.
- Teardown must unbind `UDC` first and must not use `rm -rf`.
