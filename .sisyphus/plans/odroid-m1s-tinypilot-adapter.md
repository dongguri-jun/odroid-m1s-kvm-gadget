# ODROID M1S TinyPilot-Compatible Adapter Plan

## TL;DR

> **Summary**: Build an ODROID M1S 4GB adapter layer that lets TinyPilot-style software use the board as a remote KVM substrate without creating a new KVM UI. The project must expose TinyPilot-compatible `/dev/hidg0` keyboard, `/dev/hidg1` mouse, and V4L2/uStreamer video interfaces, while documenting the Ubuntu 24.04 HID-enabled kernel requirement.
>
> **Deliverables**:
> - Public support matrix for ODROID Ubuntu 22.04, 24.04, and future 26.04 targets
> - Manual configfs HID setup and teardown scripts
> - TinyPilot-compatible keyboard and absolute mouse HID descriptors
> - Report examples for keyboard and mouse validation
> - Real-device evidence for UDC bind, `/dev/hidg0`, `/dev/hidg1`, target host enumeration, and video capture
> - TinyPilot integration guide after hardware substrate validation
>
> **Effort**: Medium to Large
> **Parallel**: YES - 4 waves
> **Critical Path**: T1 → T2 → T5 → T6 → T8 → T10 → T12

## Context

### Project direction

This repository is an external hardware adapter layer for ODROID M1S. It does not start by forking TinyPilot or building a new KVM web application.

The adapter must make ODROID M1S provide the hardware-facing interfaces that TinyPilot-style software already expects:

```text
/dev/hidg0  keyboard HID gadget
/dev/hidg1  mouse HID gadget
/dev/videoN HDMI capture as V4L2 device
uStreamer HTTP/MJPEG stream
```

### Verified image facts

- ODROID Ubuntu 22.04 server image `20251107` contains static image evidence for HID gadget support.
- ODROID Ubuntu 24.04 server image `20250522` has DWC3 OTG in DTB, but stock kernel config lacks `CONFIG_USB_CONFIGFS`, `CONFIG_USB_CONFIGFS_F_HID`, and `CONFIG_USB_F_HID`.
- 24.04 remains the preferred userspace base, but it requires a HID-enabled ODROID kernel path.

### TinyPilot compatibility facts

- TinyPilot defaults to `KEYBOARD_PATH=/dev/hidg0` and `MOUSE_PATH=/dev/hidg1`.
- TinyPilot keyboard writer sends 8-byte reports.
- TinyPilot mouse writer sends 7-byte absolute mouse reports.
- Therefore the adapter default profile should be TinyPilot-compatible keyboard plus 7-byte absolute mouse, not generic 4-byte boot mouse.

## Work Objectives

### Core Objective

Provide a verified ODROID M1S hardware substrate that TinyPilot-style software can use without modifying TinyPilot's UI or input logic.

### Deliverables

- `.sisyphus/evidence/task-*` evidence files for every task.
- `docs/hid-gadget-design.md` with exact descriptor choices and teardown safety model.
- `scripts/setup-hid-gadget.sh` and `scripts/teardown-hid-gadget.sh`.
- HID report examples under `examples/`.
- Hardware evidence checklist for real-device validation.
- uStreamer/V4L2 video capture validation plan.
- TinyPilot integration guide after hardware substrate success.

### Definition of Done

- `scripts/verify-hid-support.sh` accurately fails on unsupported kernels and passes on HID-enabled kernels.
- `scripts/setup-hid-gadget.sh` creates configfs keyboard and mouse functions without systemd.
- `scripts/teardown-hid-gadget.sh` safely unbinds UDC before removing configfs entries.
- `/dev/hidg0` is verified as keyboard and `/dev/hidg1` is verified as mouse on real ODROID M1S hardware.
- Target host enumerates the M1S as USB keyboard and mouse.
- BIOS/UEFI keyboard input is verified or explicitly blocked with evidence.
- USB HDMI capture appears as a V4L2 device and streams through uStreamer.
- TinyPilot integration guide is only written after substrate evidence exists.
- The repository never claims stock Ubuntu 24.04 kernel support unless a HID-enabled kernel is present and verified.

### Must Have

- TinyPilot-compatible `/dev/hidg0` and `/dev/hidg1` interface contract.
- Manual setup before systemd automation.
- Safe teardown with UDC unbind first.
- Public evidence with exact commands and outputs.
- Clear blocked status when hardware is unavailable.
- No local-only access notes or secrets in committed files.

### Must NOT Have

- No new KVM web UI in Phase 1.
- No TinyPilot fork until external adapter integration proves insufficient.
- No systemd automation before manual setup succeeds.
- No `rm -rf` teardown of configfs gadget directories.
- No claim that ODROID Ubuntu 24.04 stock kernel is HID-ready.
- No storage of disk images or extracted rootfs artifacts in this repository.

## Verification Strategy

Evidence must be command-driven. For hardware-dependent tasks, absence of hardware should produce explicit `BLOCKED` evidence rather than invented pass/fail results.

Evidence naming:

```text
.sisyphus/evidence/task-<N>-<slug>.md
.sisyphus/evidence/task-<N>/<artifact>.txt
```

Public evidence must not include secrets, private IP addresses, passwords, local-only serial-device details, or private logs.

## Execution Strategy

### Parallel Execution Waves

Wave 1: Pre-hardware design and scripts
- T1 HID configfs design and descriptor contract
- T2 Manual setup script
- T3 Manual teardown script
- T4 HID report examples

Wave 2: Real-device HID bring-up
- T5 Kernel and UDC runtime verification
- T6 Manual HID setup on M1S
- T7 Keyboard and mouse report validation
- T8 Teardown and repeatability validation

Wave 3: Video and TinyPilot substrate
- T9 USB HDMI capture and V4L2 inventory
- T10 uStreamer service validation
- T11 TinyPilot compatibility guide

Wave 4: Automation and release readiness
- T12 HID-enabled 24.04 kernel path
- T13 systemd service after manual success
- T14 final support matrix and release readiness review

### Dependency Matrix

- T1 blocks T2, T3, T4, T11, T13
- T2 blocks T6, T8, T13
- T3 blocks T8, T13
- T4 blocks T7
- T5 blocks T6, T7, T8
- T6 blocks T7, T8, T13
- T7 blocks T11, T14
- T8 blocks T13, T14
- T9 blocks T10, T11, T14
- T10 blocks T11, T14
- T11 blocks T14
- T12 blocks T5 for 24.04 path and T14
- T13 blocks T14

## TODOs

> Implementation + verification evidence belong to the same task.
> Every task must have acceptance criteria and QA scenarios.

### Wave 1: Pre-hardware design and scripts

- [x] 1. Define HID configfs design and descriptor contract

  **What to do**: Write `docs/hid-gadget-design.md` with the exact configfs tree, gadget identity, UDC binding strategy, keyboard descriptor, TinyPilot-compatible 7-byte absolute mouse descriptor, `/dev/hidg0`/`/dev/hidg1` ordering rules, permissions model, and safe teardown order.

  **Must NOT do**: Do not implement systemd service. Do not switch default mouse profile to 4-byte boot mouse unless TinyPilot compatibility is explicitly abandoned.

  **Parallelization**: Can Parallel: YES | Wave 1 | Blocks: T2, T3, T4, T11, T13 | Blocked By: none

  **Acceptance Criteria**:
  - [x] `test -s docs/hid-gadget-design.md`
  - [x] Document contains exact strings: `report_length=8`, `report_length=7`, `/dev/hidg0`, `/dev/hidg1`, `UDC`, `teardown`.
  - [x] Document explains why TinyPilot default mouse is 7-byte absolute mouse.

  **QA Scenarios**:
  ```text
  Scenario: HID design records TinyPilot mouse compatibility
    Tool: Bash
    Steps: grep -E "report_length=7|absolute mouse|TinyPilot" docs/hid-gadget-design.md
    Expected: all concepts are present.
    Evidence: .sisyphus/evidence/task-1-hid-design-grep.txt
  ```

- [x] 2. Implement manual HID setup script

  **What to do**: Create `scripts/setup-hid-gadget.sh` that performs root checks, configfs mount checks, kernel feature checks, stale gadget checks, keyboard-first configfs setup, mouse-second setup, UDC binding, and post-bind `/dev/hidg0`/`/dev/hidg1` validation.

  **Must NOT do**: Do not run destructive cleanup by default. Do not use `rm -rf`. Do not silently ignore missing kernel support.

  **Parallelization**: Can Parallel: PARTIAL | Wave 1 | Blocks: T6, T8, T13 | Blocked By: T1

  **Acceptance Criteria**:
  - [x] `bash -n scripts/setup-hid-gadget.sh`
  - [x] `shellcheck scripts/setup-hid-gadget.sh` if shellcheck is available
  - [x] Script has `--help`, `--force`, and `--udc` support or explicitly documents why not.
  - [x] Script has an explicit safe-failure code path when `/sys/kernel/config/usb_gadget` is missing; runtime failure validation remains part of T5/T6 hardware evidence.

  **QA Scenarios**:
  ```text
  Scenario: setup script is syntactically valid
    Tool: Bash
    Steps: bash -n scripts/setup-hid-gadget.sh
    Expected: exit 0.
    Evidence: .sisyphus/evidence/task-2-setup-bash-n.txt
  ```

- [x] 3. Implement manual HID teardown script

  **What to do**: Create `scripts/teardown-hid-gadget.sh` that unbinds UDC first, removes config symlinks, removes HID function directories, removes config strings/config, removes gadget strings, and removes the gadget directory with idempotent skip behavior.

  **Must NOT do**: Do not remove unrelated gadgets. Do not use recursive deletion. Do not remove functions while still bound.

  **Parallelization**: Can Parallel: PARTIAL | Wave 1 | Blocks: T8, T13 | Blocked By: T1

  **Acceptance Criteria**:
  - [x] `bash -n scripts/teardown-hid-gadget.sh`
  - [x] `shellcheck scripts/teardown-hid-gadget.sh` if shellcheck is available
  - [x] Script contains explicit UDC unbind before symlink/function cleanup.

  **QA Scenarios**:
  ```text
  Scenario: teardown script avoids recursive deletion
    Tool: Bash
    Steps: grep -n "rm -rf" scripts/teardown-hid-gadget.sh || true
    Expected: no matches.
    Evidence: .sisyphus/evidence/task-3-no-rm-rf.txt
  ```

- [ ] 4. Add HID report examples

  **What to do**: Add keyboard and mouse report examples under `examples/`, including key `a`, release keys, center click, and center move/click release using TinyPilot-compatible report layouts.

  **Must NOT do**: Do not assume examples were run on a real target unless evidence exists.

  **Parallelization**: Can Parallel: YES | Wave 1 | Blocks: T7 | Blocked By: T1

  **Acceptance Criteria**:
  - [ ] `examples/send-key-a.sh` exists and writes exactly 8-byte keyboard reports.
  - [ ] Mouse example writes exactly 7-byte TinyPilot absolute mouse reports.
  - [ ] All shell examples pass `bash -n`.

  **QA Scenarios**:
  ```text
  Scenario: examples use expected report sizes
    Tool: Bash
    Steps: grep -E "hidg0|hidg1|\\x04|\\xff\\x3f" examples/*
    Expected: keyboard and mouse report examples are present.
    Evidence: .sisyphus/evidence/task-4-report-example-grep.txt
  ```

### Wave 2: Real-device HID bring-up

- [ ] 5. Verify kernel and UDC runtime on ODROID M1S

  **What to do**: Run `scripts/verify-hid-support.sh` on real ODROID M1S hardware and capture kernel config, `/sys/class/udc`, configfs, and module state evidence.

  **Must NOT do**: Do not record private access details or secrets. Do not claim 24.04 stock kernel support if verification fails due to missing configfs HID options.

  **Parallelization**: Can Parallel: NO | Wave 2 | Blocks: T6, T7, T8 | Blocked By: hardware availability and HID-enabled kernel path

  **Acceptance Criteria**:
  - [ ] Evidence records kernel version.
  - [ ] Evidence records `/sys/class/udc` contents.
  - [ ] Evidence records pass/fail output from `scripts/verify-hid-support.sh`.

  **QA Scenarios**:
  ```text
  Scenario: UDC evidence is captured
    Tool: Bash on target
    Steps: ls /sys/class/udc
    Expected: output saved, even if empty.
    Evidence: .sisyphus/evidence/task-5/udc.txt
  ```

- [ ] 6. Run manual HID setup on ODROID M1S

  **What to do**: Run setup script and capture configfs tree, UDC bind, `/dev/hidg0`, `/dev/hidg1`, and `dmesg` evidence.

  **Must NOT do**: Do not proceed if T5 failed due to missing kernel support.

  **Parallelization**: Can Parallel: NO | Wave 2 | Blocks: T7, T8, T13 | Blocked By: T2, T5

  **Acceptance Criteria**:
  - [ ] `/dev/hidg0` exists.
  - [ ] `/dev/hidg1` exists.
  - [ ] Gadget `UDC` file contains a non-empty UDC name.

  **QA Scenarios**:
  ```text
  Scenario: HID device nodes are created
    Tool: Bash on target
    Steps: ls -l /dev/hidg0 /dev/hidg1
    Expected: both nodes exist.
    Evidence: .sisyphus/evidence/task-6/hidg-nodes.txt
  ```

- [ ] 7. Validate keyboard and mouse reports against target host

  **What to do**: Send the example keyboard and mouse reports to `/dev/hidg0` and `/dev/hidg1`, then record target host enumeration and input behavior.

  **Must NOT do**: Do not treat M1S-side write success as target-host success without host-side or visual evidence.

  **Parallelization**: Can Parallel: NO | Wave 2 | Blocks: T11, T14 | Blocked By: T4, T5, T6

  **Acceptance Criteria**:
  - [ ] Target host sees USB keyboard.
  - [ ] Target host sees USB mouse.
  - [ ] Keyboard `a` report and release are observed.
  - [ ] Mouse report is observed or explicitly blocked with evidence.

  **QA Scenarios**:
  ```text
  Scenario: target host enumerates HID devices
    Tool: host OS commands or screenshots
    Steps: record host-side USB/input device state after bind.
    Expected: keyboard and mouse are visible.
    Evidence: .sisyphus/evidence/task-7/target-host-enumeration.md
  ```

- [ ] 8. Validate teardown and repeatability

  **What to do**: Run teardown, confirm gadget removal, then run setup again and confirm `/dev/hidg0` and `/dev/hidg1` ordering remains stable.

  **Must NOT do**: Do not leave stale gadget state undocumented.

  **Parallelization**: Can Parallel: NO | Wave 2 | Blocks: T13, T14 | Blocked By: T3, T5, T6

  **Acceptance Criteria**:
  - [ ] Teardown removes gadget directory.
  - [ ] Re-setup recreates `/dev/hidg0` and `/dev/hidg1`.
  - [ ] No stale gadget remains after final teardown or final setup state is documented.

  **QA Scenarios**:
  ```text
  Scenario: setup-teardown cycle is repeatable
    Tool: Bash on target
    Steps: setup -> teardown -> setup -> ls /dev/hidg0 /dev/hidg1
    Expected: nodes appear after both setup runs.
    Evidence: .sisyphus/evidence/task-8/repeatability.txt
  ```

### Wave 3: Video and TinyPilot substrate

- [ ] 9. Inventory USB HDMI capture dongle as V4L2 device

  **What to do**: Connect USB HDMI capture dongle, capture `v4l2-ctl --list-devices`, `--list-formats-ext`, `lsusb`, and stable `/dev/videoN` mapping evidence.

  **Must NOT do**: Do not claim capture support from device presence alone; formats and stream test are required.

  **Parallelization**: Can Parallel: YES | Wave 3 | Blocks: T10, T11, T14 | Blocked By: capture hardware availability

  **Acceptance Criteria**:
  - [ ] Capture dongle appears in `lsusb`.
  - [ ] V4L2 device appears.
  - [ ] Supported formats/resolutions are captured.

  **QA Scenarios**:
  ```text
  Scenario: capture dongle exposes V4L2 formats
    Tool: Bash on target
    Steps: v4l2-ctl --list-formats-ext -d /dev/videoN
    Expected: output records formats and resolutions.
    Evidence: .sisyphus/evidence/task-9/v4l2-formats.txt
  ```

- [ ] 10. Validate uStreamer on the capture dongle

  **What to do**: Run uStreamer against the verified `/dev/videoN`, record process command, logs, HTTP endpoint response, and stream screenshot if safe.

  **Must NOT do**: Do not tune for performance before a basic stream is proven.

  **Parallelization**: Can Parallel: NO | Wave 3 | Blocks: T11, T14 | Blocked By: T9

  **Acceptance Criteria**:
  - [ ] uStreamer starts against the selected device.
  - [ ] HTTP endpoint responds.
  - [ ] Stream shows target video or explicit no-signal evidence.

  **QA Scenarios**:
  ```text
  Scenario: uStreamer HTTP endpoint responds
    Tool: curl or browser
    Steps: curl -I http://127.0.0.1:8080/
    Expected: HTTP response saved.
    Evidence: .sisyphus/evidence/task-10/ustreamer-http.txt
  ```

- [ ] 11. Write TinyPilot integration guide

  **What to do**: Write `docs/tinypilot-integration.md` describing how TinyPilot should see `/dev/hidg0`, `/dev/hidg1`, and uStreamer video after substrate validation.

  **Must NOT do**: Do not present guide as fully validated until T7 and T10 pass.

  **Parallelization**: Can Parallel: NO | Wave 3 | Blocks: T14 | Blocked By: T1, T7, T9, T10

  **Acceptance Criteria**:
  - [ ] Guide includes keyboard path, mouse path, and video stream assumptions.
  - [ ] Guide clearly distinguishes verified and pending steps.

  **QA Scenarios**:
  ```text
  Scenario: integration guide references substrate outputs
    Tool: Bash
    Steps: grep -E "/dev/hidg0|/dev/hidg1|uStreamer|/dev/video" docs/tinypilot-integration.md
    Expected: all substrate interfaces are documented.
    Evidence: .sisyphus/evidence/task-11-guide-grep.txt
  ```

### Wave 4: Automation and release readiness

- [ ] 12. Define HID-enabled Ubuntu 24.04 kernel path

  **What to do**: Document or implement the ODROID 24.04 kernel path that enables `CONFIG_USB_CONFIGFS`, `CONFIG_USB_CONFIGFS_F_HID`, and `CONFIG_USB_F_HID`.

  **Must NOT do**: Do not publish unverified kernel packages as supported.

  **Parallelization**: Can Parallel: YES | Wave 4 | Blocks: T5 for 24.04, T14 | Blocked By: kernel source/package availability

  **Acceptance Criteria**:
  - [ ] Required kernel options are listed.
  - [ ] Build/package/install path is documented or explicitly marked pending.
  - [ ] Support matrix reflects exact verification state.

  **QA Scenarios**:
  ```text
  Scenario: kernel requirements are explicit
    Tool: Bash
    Steps: grep -E "CONFIG_USB_CONFIGFS|CONFIG_USB_CONFIGFS_F_HID|CONFIG_USB_F_HID" docs/24.04-kernel.md docs/support-matrix.md
    Expected: required options are present.
    Evidence: .sisyphus/evidence/task-12-kernel-requirements.txt
  ```

- [ ] 13. Add systemd HID gadget service after manual success

  **What to do**: Add `systemd/odroid-m1s-hid-gadget.service` only after T6/T8 prove manual setup/teardown works.

  **Must NOT do**: Do not add boot-time automation before manual runtime evidence exists.

  **Parallelization**: Can Parallel: NO | Wave 4 | Blocks: T14 | Blocked By: T2, T3, T6, T8

  **Acceptance Criteria**:
  - [ ] Service calls setup on start and teardown on stop.
  - [ ] Service ordering accounts for configfs availability.
  - [ ] Manual evidence is referenced.

  **QA Scenarios**:
  ```text
  Scenario: systemd unit references setup and teardown scripts
    Tool: Bash
    Steps: grep -E "ExecStart=.*setup-hid-gadget|ExecStop=.*teardown-hid-gadget" systemd/odroid-m1s-hid-gadget.service
    Expected: both commands are present.
    Evidence: .sisyphus/evidence/task-13-systemd-grep.txt
  ```

- [ ] 14. Final support matrix and release readiness review

  **What to do**: Produce `.sisyphus/evidence/final/release-readiness.md` summarizing completed tasks, blockers, supported images, verified hardware, and no-ship/ship decision.

  **Must NOT do**: Do not mark release ready if HID or video substrate evidence is missing.

  **Parallelization**: Can Parallel: NO | Wave 4 | Blocks: release | Blocked By: T7, T8, T10, T11, T12, T13 where applicable

  **Acceptance Criteria**:
  - [ ] Final evidence file exists.
  - [ ] Support matrix is updated.
  - [ ] Release decision is explicit: `SHIP`, `NO-SHIP`, or `BLOCKED`.

  **QA Scenarios**:
  ```text
  Scenario: final review has an explicit verdict
    Tool: Bash
    Steps: grep -E "SHIP|NO-SHIP|BLOCKED" .sisyphus/evidence/final/release-readiness.md
    Expected: one explicit verdict appears.
    Evidence: .sisyphus/evidence/final/verdict-grep.txt
  ```

## Current Status

As of 2026-06-07:

- T1 is complete: `docs/hid-gadget-design.md` and `.sisyphus/evidence/task-1-hid-design-grep.txt` exist.
- T2 is complete: `scripts/setup-hid-gadget.sh` and `.sisyphus/evidence/task-2-setup-bash-n.txt` exist.
- T3 is complete: `scripts/teardown-hid-gadget.sh` and `.sisyphus/evidence/task-3-no-rm-rf.txt` exist.
- T4 is the next planned task: add HID report examples under `examples/`.
- Real-device HID validation is pending.
- 24.04 stock kernel is not HID-ready based on static image inspection.
- The current safe status is `PRE-HARDWARE PREPARATION`.
