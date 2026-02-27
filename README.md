# 🕰️ Legizmo

<p align="center">
  <img src="Resources/legizmo-banner.png" alt="Legizmo" width="600"/>
</p>

<p align="center">
  <a href="https://github.com/yourusername/Legizmo/releases"><img src="https://img.shields.io/github/v/release/yourusername/Legizmo?color=0a84ff&label=Latest%20Release&style=flat-square" /></a>
  <a href="https://chariz.com"><img src="https://img.shields.io/badge/Available%20on-Chariz-bf5af2?style=flat-square" /></a>
  <img src="https://img.shields.io/badge/iOS-14%20–%2016-30d158?style=flat-square" />
  <img src="https://img.shields.io/badge/watchOS-6%20–%2011-ff9f0a?style=flat-square" />
  <img src="https://img.shields.io/badge/Rootless-Supported-0a84ff?style=flat-square" />
  <img src="https://img.shields.io/badge/TrollStore-Supported-ff453a?style=flat-square" />
</p>

<p align="center">
  <b>Pair your Apple Watch running a newer watchOS with an older, jailbroken iOS device.</b><br/>
  No update required. No compromise.
</p>

---

## What is Legizmo?

Apple enforces a strict pairing requirement: your iPhone's iOS version must be equal to or newer than your Apple Watch's watchOS version. This blocks jailbreakers who stay on older iOS from using newer Apple Watches or updating watchOS.

**Legizmo breaks that restriction.**

It patches the relevant iOS daemons at runtime, spoofing version checks and bridging protocol differences so your jailbroken iPhone can pair, sync, and communicate with an Apple Watch running a newer watchOS.

---

## Features

| Feature | Description |
|---|---|
| **Pairing Support** | Bypasses the iOS version check during Apple Watch pairing |
| **Sync Support** | Keeps notifications, health data, and activity rings working |
| **Compatibility Fixes** | Per-feature patches (Blood Oxygen, ECG, Screenshot, etc.) |
| **Update Control** | Blocks incompatible watchOS OTAs; allows compatible ones |
| **Compatibility Scanner** | Scan any Apple Watch pairing QR to check watchOS version |
| **Lockdown Mode Toggle** | Enable/disable Lockdown Mode on Watch from the app |
| **TrollStore Edition** | Unjailbroken install via TrollStore on supported iOS versions |

---

## Compatibility Matrix

| Legizmo Edition | iOS Support | watchOS Support |
|---|---|---|
| **Moonstone** *(latest)* | iOS 14 – 16 | watchOS 6 – 11.x |
| **Lighthouse** | iOS 13 – 16 | watchOS 6 – 10.x |
| **Kincaid** | iOS 13 – 15 | watchOS 6 – 9.x |
| **Jupiter** | iOS 13 – 15 | watchOS 6 – 8.x |
| **Grace** | iOS 12 – 14 | watchOS 1 – 7.x |

> **Note:** Rootful XinaA15 is **not supported**. RootHide Dopamine is **not supported** for the jailbreak edition (use TrollStore edition instead).

---

## Installation

### Via Cydia / Sileo / Zebra (Jailbreak)

1. Add the Chariz repository:
   ```
   https://repo.chariz.com/
   ```
2. Search for **Legizmo Moonstone** and install.
3. Respring your device.
4. Open the **Legizmo** app from your Home Screen.

### Via TrollStore (No Jailbreak Required)

1. Download the `.tipa` from [Releases](https://github.com/yourusername/Legizmo/releases).
2. Open in TrollStore and tap **Install**.
3. Open **Legizmo** and follow the setup wizard.

---

## Building from Source

### Requirements

- macOS 12+
- [Theos](https://theos.dev) installed at `~/theos`
- Xcode Command Line Tools
- `ldid` for fakesigning

```bash
# Clone the repo
git clone https://github.com/yourusername/Legizmo.git
cd Legizmo

# Install Theos (if needed)
bash -c "$(curl -fsSL https://raw.githubusercontent.com/theos/theos/master/bin/install-theos)"

# Build (rootless)
make package THEOS_PACKAGE_SCHEME=rootless

# Build (rootful)
make package

# Install to connected device via SSH
make do
```

The `.deb` package will appear in `packages/`.

---

## Project Structure

```
Legizmo/
├── Tweak/
│   ├── Tweak.x              # Main hook file (Logos syntax)
│   ├── PairingHooks.x       # Pairing daemon patches
│   ├── SyncHooks.x          # Sync & notification hooks
│   ├── VersionSpoof.x       # iOS version spoof logic
│   └── CompatFixes/
│       ├── BloodOxygen.x    # Blood Oxygen compatibility
│       ├── ECG.x            # ECG feature bridge
│       ├── Screenshot.x     # Screenshot support fix
│       └── IconLayout.x     # Watch app icon layout
├── Preferences/
│   ├── LegizmoPrefs.plist   # Settings bundle definition
│   ├── RootListController.m # Main prefs controller
│   ├── PairingController.m  # Pairing setup controller
│   └── CompatController.m   # Compatibility fixes controller
├── Resources/
│   ├── Icon.png
│   └── legizmo-banner.png
├── layout/
│   └── DEBIAN/
│       ├── control          # Package metadata
│       ├── postinst         # Post-install script
│       └── prerm            # Pre-remove script
├── Makefile
└── control
```

---

## How It Works

Legizmo hooks into several private Apple frameworks and daemons:

### `mediaremoted` — Pairing Version Check
Apple's `mediaremoted` daemon enforces a version gate during Watch pairing. Legizmo hooks `MRPairingManager` to intercept and patch the version comparison, allowing pairing to proceed regardless of the watchOS/iOS delta.

### `companionappd` — Protocol Translation
WatchOS updates sometimes change the binary format of Bluetooth messages between Watch and iPhone. Legizmo hooks `CAWatchCompanionManager` to translate new message formats into ones the older iOS-side code understands, and vice versa.

### `healthd` — Health Feature Bridge
Features like Blood Oxygen and ECG require corresponding iOS support. Legizmo patches `HKHealthStore` internals to activate these health feature pipelines even on iOS versions that don't officially support them.

### SpringBoard / Watch App
The Watch app's version check for compatible OTA updates is hooked to block incompatible updates and permit compatible ones as defined by your installed Legizmo edition.

---

## Known Limitations

- Sending iMessages from the Watch may occasionally time out (receive/other-device send works normally)
- Music and photo syncing may be unavailable on iOS 15 and older with watchOS 9+
- Location-based watch face complications may work intermittently
- Some features depending on paired device communication may degrade with very large iOS/watchOS version gaps

---

## Contributing

Pull requests are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) before submitting.

For bug reports, open an [Issue](https://github.com/yourusername/Legizmo/issues) with:
- Your iOS version
- Your watchOS version
- Your jailbreak (Dopamine, palera1n, etc.)
- Steps to reproduce

---

## License

This project is licensed under the **MIT License** — see [LICENSE](LICENSE) for details.

---

## Credits

- Original concept & development by **lunotech11**
- Theos build system by the [Theos Team](https://theos.dev)
- Special thanks to the jailbreak community on [r/jailbreak](https://reddit.com/r/jailbreak)

---

<p align="center"><i>Legizmo is not affiliated with or endorsed by Apple Inc.</i></p>
