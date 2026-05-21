# Contributing

Thanks for helping improve HeadsetMicGuard.

## Local Setup

Requirements:

- macOS 13 or newer.
- Xcode 26.5 or newer.

Clone the project:

```sh
git clone https://github.com/ForkHorizon/HeadsetMicGuard.git
cd HeadsetMicGuard
open HeadsetMicGuard.xcodeproj
```

## Build

Debug build:

```sh
xcodebuild -project HeadsetMicGuard.xcodeproj \
  -scheme HeadsetMicGuard \
  -configuration Debug \
  -destination 'platform=macOS' \
  build CODE_SIGNING_ALLOWED=NO
```

Release build:

```sh
scripts/build-release.sh
```

DMG build:

```sh
scripts/make-dmg.sh
```

## Development Notes

- Keep the app lightweight. Prefer CoreAudio notifications over polling.
- Do not add microphone capture APIs unless the feature explicitly needs audio recording.
- Do not change output devices; the app only manages default input.
- Keep the app usable as a menu bar app with no Dock window.
- Preserve the fallback behavior: if the preferred device is unavailable, use a built-in input temporarily without overwriting the saved preference.

## Pull Requests

Before opening a pull request:

1. Run the Debug build command.
2. Run `scripts/build-release.sh`.
3. Describe the user-visible behavior change.
4. Include manual testing notes, especially for AirPods or other Bluetooth headsets when relevant.
