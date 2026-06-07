# Verification Log

This log records evidence gathered before real-hardware validation.

## 2026-06-07: ODROID Ubuntu 22.04 image static inspection

Image:

```text
ubuntu-22.04-server-odroidm1s-20251107.img
```

Findings:

```text
Kernel: 5.10.0-odroid-arm64
CONFIG_USB_OTG=y
CONFIG_USB_DWC3=y
CONFIG_USB_DWC3_DUAL_ROLE=y
CONFIG_USB_GADGET=y
CONFIG_USB_LIBCOMPOSITE=m
CONFIG_USB_F_HID=m
CONFIG_USB_CONFIGFS=m
CONFIG_USB_CONFIGFS_F_HID=y
CONFIG_USB_G_HID=m
```

DTB findings:

```text
dwc3 at fcc00000
dr_mode = "otg"
status = "okay"
```

Interpretation:

The image contains the kernel features needed for configfs HID gadget work. Runtime verification on the physical M1S is still required.

## 2026-06-07: ODROID Ubuntu 24.04 image static inspection

Image:

```text
ubuntu-24.04-server-odroidm1s-20250522.img.xz
```

Checksum:

```text
3bc5a2a3230e2e9a22f11fe2debc26c4  ubuntu-24.04-server-odroidm1s-20250522.img.xz
```

Findings:

```text
Kernel: 6.1.0-odroid-arm64
CONFIG_USB_OTG=y
CONFIG_USB_DWC3=y
CONFIG_USB_DWC3_DUAL_ROLE=y
CONFIG_USB_GADGET=y
CONFIG_USB_LIBCOMPOSITE=m
# CONFIG_USB_CONFIGFS is not set
# CONFIG_USB_G_HID is not set
```

Missing from config:

```text
CONFIG_USB_F_HID
CONFIG_USB_CONFIGFS_F_HID
```

DTB findings:

```text
usb@fcc00000
dr_mode = "otg"
status = "okay"
```

Interpretation:

The image is a viable Ubuntu 24.04 userspace base, but the stock kernel is not sufficient for HID keyboard/mouse gadget functionality. A KVM-enabled kernel is required.
