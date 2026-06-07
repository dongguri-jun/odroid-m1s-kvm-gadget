# ODROID M1S KVM Gadget

Run a TinyPilot-compatible remote KVM stack on an ODROID M1S 4GB by replacing only the board-specific hardware layer.

This project is an ODROID M1S-specific adapter for remote KVM builds. It focuses on the parts that touch the device directly: making the M1S expose USB keyboard and mouse HID gadgets through its micro USB OTG port, and wiring video capture through a standard V4L2/uStreamer path.

## Current status

This project is in early validation.

| Target | Status | Evidence |
| --- | --- | --- |
| ODROID Ubuntu 22.04 server image `20251107` | HID gadget kernel support found in image | `CONFIG_USB_CONFIGFS=m`, `CONFIG_USB_CONFIGFS_F_HID=y`, `CONFIG_USB_F_HID=m`, `CONFIG_USB_G_HID=m` |
| ODROID Ubuntu 24.04 server image `20250522` | Usable OS base, but stock kernel is not HID-ready | `CONFIG_USB_GADGET=y`, `CONFIG_USB_LIBCOMPOSITE=m`, `# CONFIG_USB_CONFIGFS is not set`, `# CONFIG_USB_G_HID is not set` |
| ODROID Ubuntu 26.04 | Not verified | No ODROID M1S-specific image has been validated yet |

The recommended direction is:

```text
Ubuntu 24.04 userspace
+ ODROID M1S kernel with USB configfs HID gadget enabled
+ HDMI-to-USB UVC capture dongle
+ uStreamer video streaming
+ TinyPilot-compatible web/control stack
```

## What this is

- A hardware and OS validation guide for ODROID M1S remote KVM builds.
- Scripts to check whether the running kernel can create USB HID gadgets.
- A setup path for creating `/dev/hidg0` and `/dev/hidg1` keyboard/mouse devices expected by TinyPilot-style software.
- A board adapter layer for uStreamer/V4L2 video capture and TinyPilot-compatible control software.

## What this is not yet

- A new KVM web application.
- A complete PiKVM replacement.
- A fork of TinyPilot by default.
- A guarantee that stock ODROID Ubuntu 24.04 can emulate keyboard/mouse without a kernel change.
- A video capture solution by itself. ODROID M1S has HDMI output, not HDMI input, so a USB HDMI capture dongle is required.

## Hardware requirements

Minimum expected hardware:

- ODROID M1S 4GB.
- Power supply for the M1S.
- Network connection.
- Micro USB OTG cable from M1S to the target computer.
- HDMI-to-USB UVC capture dongle connected to the M1S.
- HDMI cable from the target computer to the capture dongle.

## First verification step

On the ODROID M1S, run:

```bash
sudo ./scripts/verify-hid-support.sh
```

The script checks for the kernel and runtime features required before any KVM web stack can work.

## Kernel requirements

For HID gadget support, the kernel must provide at least:

```text
CONFIG_USB_GADGET=y
CONFIG_USB_LIBCOMPOSITE=m or y
CONFIG_USB_CONFIGFS=m or y
CONFIG_USB_CONFIGFS_F_HID=y
CONFIG_USB_F_HID=m or y
```

`CONFIG_USB_G_HID=m or y` is useful for legacy testing, but the preferred path is configfs with `usb_f_hid`.

## Project plan

Phase 1 is adapter-only. This repo first proves that ODROID M1S can provide the same hardware-facing interfaces TinyPilot-style software expects.

1. Verify USB device controller availability on real M1S hardware.
2. Verify HID gadget creation through configfs.
3. Create `scripts/setup-hid-gadget.sh` for manual keyboard/mouse gadget setup.
4. Create `scripts/teardown-hid-gadget.sh` for safe manual cleanup.
5. Choose TinyPilot-compatible keyboard and mouse HID descriptors.
6. Confirm `/dev/hidg0` and `/dev/hidg1` appear on the M1S.
7. Confirm the target computer detects the M1S as USB keyboard and mouse.
8. Add simple HID report examples.
9. Add uStreamer-based video capture notes.
10. Add a systemd service for boot-time gadget setup only after manual setup is verified.
11. Package or document a 24.04 kernel path with HID gadget enabled.

Later phases:

1. Add a TinyPilot integration guide.
2. Add a TinyPilot installer wrapper after HID and video are verified on real hardware.
3. Fork or patch TinyPilot only if the external adapter approach is insufficient.
