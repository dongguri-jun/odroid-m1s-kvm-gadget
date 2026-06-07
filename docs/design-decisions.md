# Design Decisions

This document records project-level decisions, trade-offs, and open questions.

## Decided

### 1. Use a TinyPilot-compatible external adapter approach

Decision:

```text
Do not create a new KVM UI or fork TinyPilot at the start.
Build an ODROID M1S hardware adapter layer that exposes the interfaces TinyPilot-style software already expects.
```

Target compatibility interfaces:

```text
/dev/hidg0  keyboard HID gadget
/dev/hidg1  mouse HID gadget
/dev/videoN HDMI capture as V4L2 device
uStreamer HTTP/MJPEG stream
```

Reason:

The user's goal is to preserve the experience of existing Raspberry Pi based KVM software while replacing only the board-specific layer that touches ODROID M1S hardware.

### 2. Treat Ubuntu 24.04 as userspace base, not as stock-kernel-ready KVM image

Decision:

```text
Ubuntu 24.04 is the preferred userspace target, but the stock ODROID 24.04 kernel is not enough for HID gadget KVM input.
```

Reason:

Static inspection of `ubuntu-24.04-server-odroidm1s-20250522.img.xz` found DWC3 OTG in DTB, but the stock kernel config lacks the configfs HID gadget options required to create `/dev/hidg0` and `/dev/hidg1`.

### 3. Start adapter-only, then add TinyPilot installer wrapper later

Decision:

```text
Start with Adapter-only.
Add a TinyPilot installer wrapper only after HID gadget and video capture are verified on real ODROID M1S hardware.
```

Reason:

The highest-risk unknown is not TinyPilot installation. It is whether the ODROID M1S 24.04 path can reliably expose the low-level HID and video interfaces TinyPilot expects.

### 4. Build manual HID gadget setup before systemd automation

Decision:

```text
Implement manual setup and teardown scripts first.
Add systemd boot-time automation only after manual HID gadget creation is verified on real hardware.
```

Reason:

The first hardware milestone needs clear failure isolation. Manual setup makes it easier to see whether failures come from kernel config, configfs, UDC binding, HID descriptors, permissions, or host PC enumeration. systemd automation should not be introduced until the manual path reliably creates `/dev/hidg0` and `/dev/hidg1`.

Initial order:

```text
scripts/setup-hid-gadget.sh
scripts/teardown-hid-gadget.sh
TinyPilot-compatible HID descriptors
manual /dev/hidg0 and /dev/hidg1 verification
target PC USB keyboard/mouse enumeration
systemd/odroid-m1s-hid-gadget.service
```

## Trade-off: Adapter-only vs installer wrapper

### Option A: Adapter-only

This repo prepares only the ODROID M1S hardware layer:

```text
HID gadget setup
/dev/hidg0 and /dev/hidg1 setup
uStreamer service setup
TinyPilot-compatible environment preparation
TinyPilot installation documented separately
```

Pros:

- Smaller scope.
- Keeps TinyPilot coupling low.
- Focuses on the unverified M1S-specific risk first.
- Easier to keep useful even if users choose different KVM web stacks.
- Makes failure causes easier to isolate during early hardware validation.

Cons:

- Final user must install TinyPilot separately.
- Not yet a one-command KVM setup.
- Documentation quality matters more because setup is split into layers.

### Option B: Adapter plus TinyPilot installer wrapper

This repo prepares ODROID M1S and also installs/configures TinyPilot:

```text
ODROID M1S preparation
HID kernel verification
TinyPilot installation
uStreamer configuration
systemd service setup
```

Pros:

- Better end-user experience.
- Closer to the Raspberry Pi TinyPilot setup experience.
- Stronger public-facing message: install this and get an ODROID M1S TinyPilot-style KVM.

Cons:

- Larger maintenance burden.
- Coupled to TinyPilot installation script changes.
- Harder to debug before the M1S hardware layer is proven.
- Expands scope before the riskiest ODROID-specific assumptions are validated.

## Roadmap implication

```text
Phase 1: Adapter-only hardware substrate
Phase 2: TinyPilot integration guide
Phase 3: TinyPilot installer wrapper
Phase 4: TinyPilot fork or patch only if external adapter integration is insufficient
```

## Open decisions
