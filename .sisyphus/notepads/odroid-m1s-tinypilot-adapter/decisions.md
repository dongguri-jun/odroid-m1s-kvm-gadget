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

## 2026-06-07 Task: t2-setup-hid-gadget

- `--force` support is intentionally narrow: it may remove only an existing unbound gadget with the same name, using explicit `rm`/`rmdir` steps and never recursive deletion.
- Setup script keeps UDC selection explicit: use `--udc` for multiple controllers, auto-select only when exactly one UDC is present.
- Setup script validates `/dev/hidg0` and `/dev/hidg1` after binding instead of assuming configfs creation was enough.

## 2026-06-07 Task: t3-teardown-hid-gadget

- Teardown is idempotent for missing paths and missing gadget state, but it only targets the named gadget directory.
- Teardown unbinds `UDC` before removing config symlinks or HID function directories.
- Teardown uses only explicit `rm` for symlinks/files and `rmdir` for directories; recursive deletion remains forbidden.

## 2026-06-07 Task: oracle-follow-up-t2-t3

- Bound gadget detection must read `UDC` content instead of using file size checks, because configfs pseudo-file sizes are not reliable.
- Both setup and teardown reject empty gadget names, `.`/`..`, and names containing `/` before building configfs paths.
- T2 evidence explicitly distinguishes pre-hardware static fail-path verification from runtime missing-configfs validation, which remains part of real-device T5/T6 evidence.

## 2026-06-07 Task: pre-hardware-test-mode

- Add `--test-root` to setup/teardown so fake configfs and fake `/dev/hidg*` nodes can be tested without privileged access or ODROID hardware.
- Keep fake-root behavior explicitly separate from real hardware support claims; it verifies script order and cleanup only.
- Document 24.04 HID-enabled kernel work as a checklist and verification gate, not as a supported prebuilt package.
