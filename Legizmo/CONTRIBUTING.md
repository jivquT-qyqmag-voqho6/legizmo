# Contributing to Legizmo

Thanks for your interest in contributing! Here's how to get started.

## Setting Up Your Dev Environment

1. Install macOS 12+ and Xcode Command Line Tools
2. Install [Theos](https://theos.dev/docs/installation)
3. Fork and clone this repo

## Code Style

- Logos (`.x`) files: use `%hook`, `%orig`, `%group`, `%init` idioms
- Objective-C: ARC enabled, use modern Objective-C syntax
- Add `NSLog(@"[Legizmo/Module] ...")` for all significant actions
- Comment any reverse-engineered private API usage with a `// ── Private` block

## Submitting a PR

1. Create a branch: `git checkout -b fix/your-fix-name`
2. Make your changes and test on device
3. Run `make package` and confirm the `.deb` builds cleanly
4. Open a PR with:
   - What the fix/feature does
   - iOS and watchOS versions tested on
   - Your jailbreak tool (Dopamine, palera1n, etc.)

## Reporting Bugs

Open an [Issue](https://github.com/yourusername/Legizmo/issues) with:
- iOS version
- watchOS version
- Jailbreak used
- Steps to reproduce
- Syslog output (grab with `idevicesyslog` or Cr4shed)

## Reverse Engineering Notes

Private APIs are documented in `Tweak/` header comments. If you discover a new
private method relevant to pairing or sync, document it in a comment before hooking.

All contributors must agree to the MIT License terms.
