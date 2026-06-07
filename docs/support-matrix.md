# Support Matrix

This matrix records verified facts only. Do not mark an image as supported until the listed checks are complete.

## Image validation

| Board | Image | Kernel | USB OTG DTB | HID gadget kernel config | Runtime HID verified | Status |
| --- | --- | --- | --- | --- | --- | --- |
| ODROID M1S 4GB | Ubuntu 22.04 server `20251107` | `5.10.0-odroid-arm64` | `dr_mode = "otg"`, `status = "okay"`, DWC3 at `fcc00000` | Present | Not yet | Static image evidence supports HID gadget |
| ODROID M1S 4GB | Ubuntu 24.04 server `20250522` | `6.1.0-odroid-arm64` | `usb@fcc00000`, `dr_mode = "otg"`, `status = "okay"` | Missing in stock kernel | Not applicable until kernel is fixed | Good OS base, kernel needs HID enablement |
| ODROID M1S 4GB | Ubuntu 26.04 | Not verified | Not verified | Not verified | Not verified | Future target |

## Required checks

A release should not claim support until these checks pass on real hardware:

1. `/sys/class/udc` contains the real USB device controller.
2. `modprobe libcomposite` succeeds when `libcomposite` is modular.
3. `mount -t configfs none /sys/kernel/config` succeeds or configfs is already mounted.
4. `/sys/kernel/config/usb_gadget` exists.
5. HID functions can be created under configfs.
6. `/dev/hidg0` and `/dev/hidg1` appear.
7. A target computer detects the M1S as USB keyboard and mouse.
8. Keyboard input works in BIOS/UEFI, not only after the target OS boots.
9. USB HDMI capture works at the chosen resolution.
10. Video streaming and HID injection work at the same time.

## 24.04 interpretation

The validated 24.04 image is suitable as a userspace base, but its stock kernel is not sufficient for the HID part of a remote KVM. A 24.04-based project therefore needs one of these paths:

1. Rebuild the ODROID 6.1 kernel with USB configfs HID gadget support enabled.
2. Install a vendor or project-provided ODROID kernel package that includes those options.
3. Use 22.04 as a temporary proof-of-concept baseline while preparing the 24.04 kernel path.
