# PianoBridge 

**PianoBridge** is a native background utility for iOS 6 that breathes new life into legacy 30-pin accessories. It acts as a bridge between proprietary Gear4 keyboards and the modern iOS CoreMIDI system. 

Instead of relying on outdated, unsupported apps, PianoBridge intercepts the raw bitmask data from the accessory port, translates it into standard MIDI Note On/Off commands on the fly, and injects them into a virtual MIDI source (`PocketLoops`). 

This allows you to play your old dock-connected keyboards in any modern synthesizer app (like GarageBand) while PianoBridge quietly runs in the background!

## Features
* **True CoreMIDI Support:** Turns a closed-protocol accessory into a universal MIDI controller.
* **Background Execution:** Fully supports iOS background audio and external accessory modes. You can launch it, connect the keyboard, switch to GarageBand, and keep playing.
* **Zero Latency:** Direct bitwise translation of the hardware stream via `EASession` ensures instantaneous note playback.

## How to Adapt This for Other Accessories
This project is essentially a template. If you have a different abandoned 30-pin or Lightning music gadget (like an old drum pad, DJ controller, or synth), you can fork this repo and adapt it:

1. **Find the Protocol String:** Every accessory has a reverse-engineered or official protocol name (e.g., `com.yamaha.midi` or `com.akaimpc.pad`). You need to replace `com.gear4.keyboard` with your gadget's protocol in two places:
   * [cite_start]`Info.plist` (under `UISupportedExternalAccessoryProtocols`) [cite: 4]
   * `XXAppDelegate.m` (in the `didFinishLaunchingWithOptions` loop)
2. [cite_start]**Keep the Entitlements:** The `entitlements.plist` contains `<key>com.apple.private.externalaccessory.showall</key> <true/>`[cite: 2]. Do not remove this! It is the "magic key" that forces older iOS versions to expose raw data streams for accessories Apple might otherwise hide.
3. **Reverse Engineer the Byte Stream:** In `XXAppDelegate.m`, look at the `readData:` method. To adapt for a new gadget, simply `NSLog` the raw bytes coming from the `NSInputStream`. Press buttons on your gadget and watch the console to figure out the bitmask or hex payloads it sends.
4. **Map to CoreMIDI:** Once you know which bytes correspond to which buttons, change the logic in `sendNote:velocity:` to fire standard `CoreMIDI` events (Note On/Off, Control Change, Pitch Bend). 

## Building and Installation
This project is built using [Theos](https://github.com/theos/theos).

1. Clone this repository.
2. Ensure you have Theos installed and the iOS 6 SDK set up.
3. Set your device's IP address in the `Makefile` (using the `THEOS_DEVICE_IP` variable).
4. Build and install using the following command:
   ```bash
   make package install

```

## How to Use

1. Launch the **PianoBridge** app on your device.
2. Connect your Gear4 keyboard to the 30-pin dock connector.
3. The app will detect the accessory and establish an active session (the screen background will turn green upon successful connection).
4. Press the Home button to send PianoBridge to the background.
5. Open GarageBand (or any other CoreMIDI-compatible app), select a synthesizer, and start playing!

## Technical Details

* **ExternalAccessory Framework:** Used to open an `EASession` and read the raw input stream from the keyboard.
* **CoreMIDI Framework:** Used to create a virtual MIDI Client and Source, packaging the translated bytes into `MIDIPacketList` structures for the system to recognize.

## License

MIT License
