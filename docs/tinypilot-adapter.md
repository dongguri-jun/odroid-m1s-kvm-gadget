# TinyPilot-Compatible Adapter Design

## Decision

This project starts as an external adapter layer for TinyPilot-style KVM builds on ODROID M1S.

The goal is not to create a new KVM UI or fork TinyPilot immediately. The goal is to make ODROID M1S provide the same low-level interfaces that Raspberry Pi based TinyPilot-style setups expect.

## Compatibility target

The adapter should provide these stable interfaces:

```text
/dev/hidg0  keyboard HID gadget
/dev/hidg1  mouse HID gadget
/dev/videoN HDMI capture as V4L2 device
uStreamer HTTP/MJPEG stream
```

TinyPilot-style software can then keep using its existing keyboard, mouse, and video assumptions.

## Boundary

### Owned by this adapter

- Kernel capability verification.
- ODROID M1S USB OTG/UDC verification.
- Configfs HID gadget setup.
- Creation of keyboard and mouse HID functions.
- Binding the gadget to the real ODROID M1S UDC.
- Permissions or udev rules for `/dev/hidg0` and `/dev/hidg1`.
- uStreamer service configuration for USB HDMI capture dongles.
- Documentation for ODROID Ubuntu 24.04 kernel requirements.

### Not owned by this adapter initially

- Rewriting the TinyPilot web UI.
- Reimplementing TinyPilot keyboard/mouse event handling.
- Replacing uStreamer.
- Implementing a full PiKVM-compatible OS image.
- ATX power control.
- Virtual media.
- Multi-user access control.

## Why not fork TinyPilot first

Starting as an external adapter keeps the hardware work isolated. Forking TinyPilot should happen only if a verified integration requires code changes inside TinyPilot itself.

The first question this project should answer is:

```text
Can ODROID M1S expose the same /dev/hidg0 and /dev/hidg1 interfaces that TinyPilot already knows how to use?
```

If the answer is yes, most of the first integration can remain outside TinyPilot.

## Expected runtime stack

```text
Target computer
  HDMI output
    -> USB HDMI capture dongle
      -> ODROID M1S /dev/videoN
        -> uStreamer
          -> TinyPilot-compatible web/video UI

TinyPilot-compatible keyboard/mouse events
  -> /dev/hidg0 and /dev/hidg1
    -> ODROID M1S micro USB OTG port
      -> target computer USB host port
```

## First implementation milestone

The first milestone is not a full KVM. It is a hardware compatibility layer:

1. Verify kernel support.
2. Verify UDC availability.
3. Create `scripts/setup-hid-gadget.sh` for manual configfs keyboard and mouse gadget setup.
4. Create `scripts/teardown-hid-gadget.sh` for safe manual cleanup.
5. Choose TinyPilot-compatible keyboard and mouse HID descriptors.
6. Confirm `/dev/hidg0` and `/dev/hidg1` appear.
7. Send one keyboard report to the target host.
8. Send one mouse report to the target host.
9. Confirm the target host enumerates the M1S as USB keyboard and mouse.
10. Confirm uStreamer can stream the HDMI capture dongle.
11. Add systemd boot-time automation only after the manual path is verified.

Only after this should TinyPilot installation and integration be automated.

## Open design questions

1. Should the adapter use TinyPilot's exact gadget descriptors, or define ODROID-specific descriptors that preserve `/dev/hidg0` and `/dev/hidg1` compatibility?
2. Should 24.04 support ship as a kernel build guide first, or as a prebuilt kernel package later?
3. Which USB HDMI capture dongles should be listed as verified first?
