# Hardware Notes

## Required hardware

| Item | Purpose | Notes |
| --- | --- | --- |
| ODROID M1S 4GB | KVM controller | Runs the web/video/HID control stack. |
| M1S power supply | Power | The target computer should not be the only power source. |
| Network connection | Remote access | Ethernet is preferred for stable KVM use. |
| Micro USB OTG cable | USB HID device link to target computer | Connects the M1S OTG port to the target computer's USB host port. |
| HDMI-to-USB UVC capture dongle | Video input | M1S has HDMI output, not HDMI input. |
| HDMI cable | Target video path | Target computer HDMI output goes into the capture dongle. |

## Signal flow

```text
Target computer HDMI output
    -> HDMI cable
    -> USB HDMI capture dongle
    -> ODROID M1S USB host port
    -> video streamer
    -> browser UI

Browser keyboard/mouse events
    -> ODROID M1S HID service
    -> /dev/hidg0 and /dev/hidg1
    -> M1S micro USB OTG port
    -> target computer USB host port
```

## Important limitation

The ODROID M1S cannot capture HDMI directly. Its HDMI connector is an output. Remote KVM video therefore requires an external HDMI capture device.

## Real-hardware validation checklist

- The target computer sees the M1S as a USB keyboard.
- The target computer sees the M1S as a USB mouse.
- Keyboard input works before the target OS boots.
- Mouse input works after the target OS boots.
- The capture dongle appears as a V4L2 device on the M1S.
- Video streaming and HID input work at the same time.
