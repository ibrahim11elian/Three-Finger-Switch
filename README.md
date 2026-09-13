# Three Finger Switch

<img src="AppResources/AppIcon.png" width="128" alt="Three Finger Switch icon">

A focused macOS menu-bar utility that makes three-finger horizontal swipes behave like a stable app
carousel:

- swipe left → previous app;
- swipe right → next app;
- reverse direction → return to the app you just left.

It switches immediately, without showing the Command-Tab interface or waiting for another click.

## Features

- Exact three-finger detection on built-in and supported external trackpads
- Stable, bidirectional order across all open regular applications
- Adjustable sensitivity and reversible directions
- Per-app exclusions and custom app ordering
- Optional destination app indicator
- Drag protection, rapid-swipe handling, and sleep/wake recovery
- Launch at Login
- Native light and dark appearance

## Install

Download the latest notarized ZIP from the repository’s **Releases** page, unzip it, and move
**Three Finger Switch.app** to `/Applications`. Open it once; afterward it lives in the menu bar.

In **System Settings → Trackpad → More Gestures**, set **Swipe between full-screen applications** to
four fingers or turn it off. This prevents macOS from also changing Spaces when you use this app’s
three-finger gesture.

The app does not need Accessibility, Screen Recording, or network access.

## Build from source

macOS Command Line Tools are enough for a local build:

```sh
./scripts/render-app-icon.sh
./scripts/build-app.sh
```

The app is created at `outputs/Three Finger Switch.app`. A local build is ad-hoc signed and is meant
for use on the Mac that built it.

To build a universal binary for Apple silicon and Intel Macs:

```sh
ARCHS="arm64 x86_64" ./scripts/build-app.sh
```

## Public releases

GitHub Actions runs checks for each pull request. Pushing a tag such as `v2.1.0` creates a universal,
Developer ID-signed, notarized, and stapled GitHub Release.

Before the first public tag:

1. Join the Apple Developer Program and create a **Developer ID Application** certificate.
2. Export that certificate and private key as a password-protected `.p12` file.
3. Choose a permanent bundle identifier and add it as the repository variable
   `BUNDLE_IDENTIFIER`. Do this before the first release because changing it later resets preferences
   and Launch at Login registration.
4. Add these GitHub Actions secrets:

   - `APPLE_DEVELOPER_ID_P12_BASE64` — the `.p12` encoded with `base64 -i certificate.p12`;
   - `APPLE_DEVELOPER_ID_P12_PASSWORD`;
   - `APPLE_DEVELOPER_ID_APPLICATION` — the full identity, for example
     `Developer ID Application: Your Name (TEAMID)`;
   - `APPLE_CI_KEYCHAIN_PASSWORD` — a strong throwaway password used for the CI keychain;
   - `APPLE_ID`;
   - `APPLE_TEAM_ID`;
   - `APPLE_APP_SPECIFIC_PASSWORD`.

For a release from your own Mac, store notarization credentials in Keychain, then run:

```sh
xcrun notarytool store-credentials "three-finger-switch"
CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
NOTARY_PROFILE="three-finger-switch" \
./scripts/package-release.sh
```

Never publish the ad-hoc-signed local build as a release. Gatekeeper treats a downloaded unsigned or
ad-hoc-signed app differently from a Developer ID-signed and notarized app.

## Privacy

Three Finger Switch runs locally. It does not collect analytics, send network requests, read screen
contents, or store a history of the apps you use. Preferences stay in macOS `UserDefaults`.

## Compatibility and private API

macOS does not provide a public global API for exact trackpad contact counts. Three Finger Switch
dynamically loads Apple’s private `MultitouchSupport` framework for that one purpose. This means:

- Mac App Store distribution is not supported;
- a future macOS update could require a compatibility update;
- every release should be tested on the newest macOS before publishing.

Developer ID notarization is separate from Mac App Store review and is the intended distribution
path for GitHub downloads.

## Uninstall

Turn off **Launch at Login** in Settings, quit from the menu-bar item, then move
`/Applications/Three Finger Switch.app` to the Trash.

## License

MIT — see [LICENSE](LICENSE).
