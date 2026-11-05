<div align="center">
  <img src="tomatiicon.svg" width="240" alt="Tomati app icon">

  <h1>Tomati</h1>

  <p>A compact focus timer for the macOS menu bar.</p>

  <a href="https://github.com/emilianooowo/Tomati/releases/latest">
    <img src="https://img.shields.io/badge/Download-Latest%20release-E53935?style=for-the-badge&logo=github&logoColor=white" alt="Download the latest Tomati release">
  </a>

  <p><sub>Built with SwiftUI and AppKit</sub></p>

  <p><sub>Requires macOS 14 Sonoma or later</sub></p>
</div>

---

Tomati keeps focus controls close without occupying the Dock. Choose a duration, use a preset, or start a complete session with automatic breaks.

## Features

- Choose any duration from a compact animated minute scale.
- Start quickly from one to four custom presets.
- Create focus sessions with automatic breaks and custom colors.
- Pause, resume, reset, and follow overtime from the menu bar.
- Personalize the accent color, sound, and menu bar icon.
- Check for updates securely from About Tomati with Sparkle.

## Install

Tomati requires **macOS 14 Sonoma or later** and a Mac with Apple silicon.

1. Open the [latest release](https://github.com/emilianooowo/Tomati/releases/latest).
2. Download the ZIP file under **Assets**.
3. Open the ZIP and move `Tomati.app` to **Applications**.
4. Launch Tomati. Its icon will appear in the menu bar.

### First launch

Tomati is currently distributed outside the Mac App Store. If macOS blocks it:

1. Hold Control, click `Tomati.app`, and choose **Open**.
2. If it remains blocked, open **System Settings → Privacy & Security**.
3. Find Tomati in the Security section and click **Open Anyway**.

This confirmation is only required on the first launch.

## Use

### Timer

Drag the minute scale, choose a preset, and press Play. The popup becomes compact while the timer is active and keeps Pause and Reset available.

### Sessions

Create sessions from **Settings → Sessions**. Choose the number of focus intervals, focus duration, break duration, and accent color.

A session with three focus intervals runs as:

`Focus 1 → Rest → Focus 2 → Rest → Focus 3 → Complete`

## Settings

- **General:** Accent, menu bar icon, scale limit, and presets.
- **Sessions:** Focus intervals, breaks, and session colors.
- **System:** Login and Dock behavior.
- **Sounds:** Alarm selection and preview.
- **About:** Version, repository, and update checks.
- **What’s New:** Compact release history.

## Build

1. Clone this repository.
2. Open `Tomati.xcodeproj` in Xcode.
3. Select the Tomati scheme and run the app.

## Feedback

Report bugs or suggest improvements in [GitHub Issues](https://github.com/emilianooowo/Tomati/issues).

## License

Tomati is available under the [MIT License](LICENSE).
