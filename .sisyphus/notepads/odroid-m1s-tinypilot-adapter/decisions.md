# Decisions

## 2026-06-07 Task: schedule-system-start

- Active plan selected: `.sisyphus/plans/odroid-m1s-tinypilot-adapter.md`.
- Project direction is TinyPilot-compatible external adapter, not a new KVM UI.
- Phase 1 starts adapter-only: prove ODROID M1S can expose TinyPilot-compatible `/dev/hidg0`, `/dev/hidg1`, and V4L2/uStreamer interfaces before automating TinyPilot installation.
- Manual HID setup and teardown scripts come before systemd automation.
- Default mouse profile for TinyPilot compatibility is 7-byte absolute mouse, because TinyPilot writes 7-byte mouse reports to `/dev/hidg1`.
