# HID Gadget Design

This document defines the manual USB HID gadget design for the ODROID M1S TinyPilot-compatible adapter.

The goal is to make ODROID M1S expose the same low-level input interfaces TinyPilot-style software already expects:

```text
/dev/hidg0  keyboard HID gadget
/dev/hidg1  mouse HID gadget
```

This design intentionally covers the manual configfs path only. systemd automation comes later, after real-device setup, teardown, and target-host enumeration are verified.

## Compatibility contract

The default profile must match TinyPilot's existing HID assumptions:

| Interface | Device node | Function name | Report length | Role |
| --- | --- | --- | --- | --- |
| Keyboard | `/dev/hidg0` | `hid.usb0` | `report_length=8` | Boot-style USB keyboard |
| Mouse | `/dev/hidg1` | `hid.usb1` | `report_length=7` | TinyPilot-compatible absolute mouse |

The ordering matters. The setup script must create and link the keyboard function first, then the mouse function, so the expected device nodes are stable:

```text
functions/hid.usb0 -> /dev/hidg0
functions/hid.usb1 -> /dev/hidg1
```

If a future kernel enumerates these differently, the setup script must fail or warn rather than silently presenting the wrong path to TinyPilot.

## Kernel and runtime prerequisites

The preferred path uses `libcomposite` plus configfs HID functions.

Required kernel options:

```text
CONFIG_USB_GADGET=y
CONFIG_USB_LIBCOMPOSITE=m or y
CONFIG_USB_CONFIGFS=m or y
CONFIG_USB_CONFIGFS_F_HID=y
CONFIG_USB_F_HID=m or y
```

Useful legacy test option:

```text
CONFIG_USB_G_HID=m or y
```

Required runtime paths:

```text
/sys/kernel/config
/sys/kernel/config/usb_gadget
/sys/class/udc
```

The current stock ODROID Ubuntu 24.04 image is not HID-ready because its kernel config lacks `CONFIG_USB_CONFIGFS`, `CONFIG_USB_CONFIGFS_F_HID`, and `CONFIG_USB_F_HID`. Ubuntu 24.04 remains the preferred userspace base, but this design requires a HID-enabled ODROID kernel.

## Gadget identity

Use one composite gadget with keyboard and mouse HID functions.

Default gadget name:

```text
odroid_m1s_kvm
```

Default configfs root:

```text
/sys/kernel/config/usb_gadget/odroid_m1s_kvm
```

Default USB identity should stay conservative and recognizable during early validation:

```text
idVendor  = 0x1d6b  # Linux Foundation, matching TinyPilot's generic gadget default
idProduct = 0x0104  # Multifunction Composite Gadget
bcdDevice = 0x0100
bcdUSB    = 0x0200
```

Default strings:

```text
manufacturer = odroid-m1s-kvm-gadget
product      = ODROID M1S TinyPilot-Compatible KVM Gadget
serialnumber = odroid-m1s-kvm-gadget
```

These strings are not security-sensitive. They are intended to make target-host USB enumeration easy to recognize in evidence.

## Configfs tree

The setup script should create this tree:

```text
/sys/kernel/config/usb_gadget/odroid_m1s_kvm/
  idVendor
  idProduct
  bcdDevice
  bcdUSB
  strings/0x409/
    serialnumber
    manufacturer
    product
  functions/
    hid.usb0/
      protocol
      subclass
      report_length
      report_desc
      no_out_endpoint  # optional, only when supported by the kernel
    hid.usb1/
      protocol
      subclass
      report_length
      report_desc
  configs/c.1/
    MaxPower
    strings/0x409/
      configuration
    hid.usb0 -> ../../functions/hid.usb0
    hid.usb1 -> ../../functions/hid.usb1
  UDC
```

Recommended config values:

```text
configs/c.1/MaxPower = 250
configs/c.1/strings/0x409/configuration = HID keyboard and mouse
```

## UDC selection and binding

The setup script must not assume the UDC name. ODROID M1S static DTB evidence shows the DWC3 controller at `usb@fcc00000`, but the runtime UDC name must be read from the target system.

Selection rules:

1. If `--udc <name>` is provided, bind to that exact UDC after confirming it exists under `/sys/class/udc`.
2. If no `--udc` is provided and exactly one UDC exists, use it.
3. If no UDC exists, fail with a clear message and tell the operator to check OTG cable, kernel role, and device-controller support.
4. If multiple UDCs exist, fail unless `--udc` is provided.

Binding step:

```text
echo "${udc_name}" > /sys/kernel/config/usb_gadget/odroid_m1s_kvm/UDC
```

Post-bind checks:

```text
test -n "$(cat /sys/kernel/config/usb_gadget/odroid_m1s_kvm/UDC)"
test -e /dev/hidg0
test -e /dev/hidg1
```

## Keyboard function

Function path:

```text
functions/hid.usb0
```

Config values:

```text
protocol=1
subclass=1
report_length=8
```

Reasoning:

- `protocol=1` selects keyboard protocol.
- `subclass=1` selects boot interface subclass.
- `report_length=8` matches TinyPilot keyboard writes and common boot keyboard reports.

Keyboard report layout:

```text
byte 0  modifier bits
byte 1  reserved
byte 2  keycode 1
byte 3  keycode 2
byte 4  keycode 3
byte 5  keycode 4
byte 6  keycode 5
byte 7  keycode 6
```

TinyPilot sends key `a` as an 8-byte report with keycode `0x04`, then releases with eight zero bytes.

Keyboard HID report descriptor bytes:

```text
05 01 09 06 A1 01 05 08 19 01 29 03 15 00 25 01
75 01 95 03 91 02 09 4B 95 01 91 02 95 04 91 01
05 07 19 E0 29 E7 95 08 81 02 75 08 95 01 81 01
19 00 29 91 26 FF 00 95 06 81 00 C0
```

If the kernel exposes `functions/hid.usb0/no_out_endpoint`, set it to `1` for pre-boot friendliness, matching TinyPilot's optional behavior:

```text
echo 1 > functions/hid.usb0/no_out_endpoint
```

## Mouse function

Function path:

```text
functions/hid.usb1
```

Config values:

```text
protocol=0
subclass=0
report_length=7
```

Reasoning:

TinyPilot's mouse writer sends 7-byte absolute mouse reports, not a generic 4-byte relative boot mouse. Preserving that contract lets TinyPilot-style software keep its existing input scaling and path assumptions.

Mouse report layout:

```text
byte 0    button bits
byte 1-2  X absolute coordinate, little-endian, 0..32767
byte 3-4  Y absolute coordinate, little-endian, 0..32767
byte 5    vertical wheel, signed 8-bit relative delta
byte 6    horizontal wheel, signed 8-bit relative delta
```

Examples:

```text
center position: X=16383 -> ff 3f, Y=16383 -> ff 3f
center no-click report: 00 ff 3f ff 3f 00 00
center left-click report: 01 ff 3f ff 3f 00 00
release at center: 00 ff 3f ff 3f 00 00
```

Mouse HID report descriptor bytes:

```text
05 01 09 02 A1 01 05 09 19 01 29 08 15 00 25 01
95 08 75 01 81 02 05 01 09 30 09 31 16 00 00 26
FF 7F 75 10 95 02 81 02 09 38 15 81 25 7F 75 08
95 01 81 06 05 0C 0A 38 02 15 81 25 7F 75 08 95
01 81 06 C0
```

## Permissions model

Early manual validation can run HID report examples as root.

After manual verification, the adapter should add a narrow permission mechanism for TinyPilot-style services:

1. Prefer a dedicated group, for example `kvm-gadget`.
2. Use udev rules or setup-script ownership changes for `/dev/hidg0` and `/dev/hidg1`.
3. Grant write access only to the HID gadget device nodes.
4. Do not grant broad write access to configfs or unrelated `/dev` paths.

The setup script should print the resulting ownership and mode of `/dev/hidg0` and `/dev/hidg1` as evidence.

## Safe setup order

The manual setup script should follow this order:

1. Confirm it is running as root.
2. Load `libcomposite` if needed.
3. Confirm `/sys/kernel/config` is mounted.
4. Confirm `/sys/kernel/config/usb_gadget` exists.
5. Confirm required configfs HID support is present.
6. Confirm no existing `odroid_m1s_kvm` gadget is bound unless `--force` is explicitly requested.
7. Create gadget directory and USB identity files.
8. Create strings.
9. Create `functions/hid.usb0` keyboard first.
10. Write keyboard `report_desc` and `report_length=8`.
11. Create `functions/hid.usb1` mouse second.
12. Write mouse `report_desc` and `report_length=7`.
13. Create `configs/c.1` and config strings.
14. Link `hid.usb0` first and `hid.usb1` second.
15. Select UDC.
16. Bind UDC.
17. Verify `/dev/hidg0` and `/dev/hidg1`.
18. Print command evidence hints for target-host enumeration.

## Safe teardown order

The teardown script must unbind the UDC before removing functions or symlinks.

Required order:

1. Confirm it is running as root.
2. Locate `/sys/kernel/config/usb_gadget/odroid_m1s_kvm`.
3. If `UDC` is non-empty, write an empty string to unbind:

   ```text
   echo "" > UDC
   ```

4. Remove config symlinks one by one:

   ```text
   rm configs/c.1/hid.usb1
   rm configs/c.1/hid.usb0
   ```

5. Remove HID function directories one by one:

   ```text
   rmdir functions/hid.usb1
   rmdir functions/hid.usb0
   ```

6. Remove config string directory and config directory.
7. Remove gadget string directory.
8. Remove gadget directory.

The teardown script must not use `rm -rf`. Recursive deletion can hide mistakes and risks deleting unrelated configfs state. Missing paths should be handled as idempotent skips with clear messages.

## Failure behavior

The scripts should fail clearly for these cases:

| Failure | Expected behavior |
| --- | --- |
| Not root | Exit non-zero and say root is required |
| Missing configfs | Exit non-zero and point to `/sys/kernel/config` |
| Missing `usb_gadget` configfs path | Exit non-zero and point to kernel configfs gadget support |
| No UDC | Exit non-zero and save blocked evidence |
| Multiple UDCs without `--udc` | Exit non-zero and list candidates |
| Existing bound gadget | Exit non-zero unless explicit teardown or `--force` path is used |
| Missing `/dev/hidg0` or `/dev/hidg1` after bind | Exit non-zero and print configfs/UDC state |

## Validation evidence for T1

This design is considered complete when these commands succeed on the repo:

```bash
test -s docs/hid-gadget-design.md
grep -E "report_length=8|report_length=7|/dev/hidg0|/dev/hidg1|UDC|teardown" docs/hid-gadget-design.md
```

The grep output should be saved as:

```text
.sisyphus/evidence/task-1-hid-design-grep.txt
```
