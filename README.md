# Tomati

A compact focus timer that lives in the macOS menu bar. Built with SwiftUI and AppKit.

<p>
  <img src="tomatiicon.svg" width="128" alt="Tomati app icon">
</p>

Tomati stays out of the way while keeping the controls you need close at hand. Choose a duration, start a quick preset, or run a complete focus session with automatic breaks.

[![Descargar la última versión de Tomati](https://img.shields.io/badge/Descargar-Última%20versión-E53935?style=for-the-badge&logo=github&logoColor=white)](https://github.com/emilianooowo/Tomati/releases/latest)

## Download

1. Open the [latest release](https://github.com/emilianooowo/Tomati/releases/latest).
2. Under **Assets**, download `Tomati-2.1.0.zip`.
3. Double-click the ZIP file to extract it.
4. Drag `Tomati.app` into your **Applications** folder.
5. Open Tomati. Its icon will appear in the macOS menu bar; the app does not appear in the Dock.

### If macOS blocks the first launch

Because Tomati is distributed outside the Mac App Store, Gatekeeper may ask for confirmation:

1. Control-click `Tomati.app` in Applications and choose **Open**.
2. If macOS still blocks it, open **System Settings → Privacy & Security**.
3. Scroll to the Security section and click **Open Anyway** next to Tomati.
4. Confirm by clicking **Open**.

You only need to do this for the first launch.

## Features

- **Menu bar app:** Runs without a Dock icon or permanent window.
- **Quick timer:** Select any duration from the minute scale or use a quick preset.
- **Focus sessions:** Create named sessions with multiple focus intervals and automatic breaks.
- **Custom session colors:** Give every saved session its own accent color.
- **Flexible presets:** Keep between one and four quick-start presets and edit them at any time.
- **Compact preset menu:** Open every quick timer from a single menu bar control.
- **Visual progress:** The popup background and menu bar icon show the remaining time.
- **Overtime alert:** The alarm increases gradually and the menu bar icon pulses when time is up.
- **Liquid Glass controls:** Compact native controls that adapt to light and dark mode.
- **Native sounds:** Choose a macOS system sound and preview it directly from Settings.
- **Built-in updates:** Check for new versions securely from About Tomati using Sparkle.

## Using Tomati

### Start a regular timer

- Drag the minute scale left or right to choose a duration, then press Play.
- Alternatively, click a preset or select a duration and press Play.
- Use Pause to suspend the timer and Reset to stop it.

### Start a focus session

1. Open **Settings → Sessions**.
2. Create a session and choose its name, number of focus intervals, focus duration, break duration, and accent color.
3. Return to the popup and click the Sessions button.
4. Select the session you want to start.

A session automatically alternates between focus and rest. For example, a session with three focus intervals runs as:

`Focus 1 → Rest → Focus 2 → Rest → Focus 3 → Complete`

## Settings

### General

- App accent color
- Menu bar icon
- Minute-scale limit
- One to four quick presets
- Alarm sound with hover preview

### Sessions

- Create, edit, and delete focus sessions
- Configure focus intervals and breaks
- Assign an individual accent color to each session

### System, Sounds & Updates

- Choose whether Tomati launches at login or appears in the Dock
- Select and preview the alarm sound
- Review what changed in the current version
- Check for updates directly from About Tomati

## Build from source

1. Clone this repository.
2. Open `Tomati.xcodeproj` in Xcode.
3. Select the Tomati scheme and run the app.

Tomati uses SwiftUI, AppKit, `NSPopover`, and the `LSUIElement` app mode.

## Feedback

Use [GitHub Issues](https://github.com/emilianooowo/Tomati/issues) to report a bug or suggest an improvement.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
