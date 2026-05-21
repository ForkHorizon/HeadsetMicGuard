# Releasing HeadsetMicGuard

This checklist is for maintainers publishing GitHub releases.

## Release Version

The first public release is `v1.0`.

Project settings:

- `MARKETING_VERSION = 1.0`
- `CURRENT_PROJECT_VERSION = 1`
- `MACOSX_DEPLOYMENT_TARGET = 13.0`

## Local Release Build

```sh
scripts/build-release.sh
scripts/make-dmg.sh
```

Output:

```text
build/release/HeadsetMicGuard.app
build/release/HeadsetMicGuard-1.0.dmg
```

## Optional Signing

For a signed build, provide a Developer ID Application identity:

```sh
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" scripts/make-dmg.sh
```

The script passes the identity to Xcode for app signing and signs the resulting DMG.

## Optional Notarization

Use either a notarytool keychain profile:

```sh
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
NOTARY_PROFILE="HeadsetMicGuardNotary" \
scripts/make-dmg.sh
```

Or Apple ID credentials:

```sh
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
APPLE_ID="you@example.com" \
APPLE_TEAM_ID="TEAMID" \
APPLE_APP_SPECIFIC_PASSWORD="xxxx-xxxx-xxxx-xxxx" \
scripts/make-dmg.sh
```

When notarization succeeds, the script staples the ticket to the DMG.

## GitHub Release

1. Confirm `CHANGELOG.md` is updated.
2. Confirm the Release workflow has the required signing secrets if publishing a notarized build.
3. Create and push a tag:

```sh
git tag v1.0
git push origin v1.0
```

4. The Release workflow builds the DMG and attaches it to the GitHub Release.

## GitHub Secrets For Signed Releases

Optional secrets:

- `MACOS_CERTIFICATE_P12`: base64-encoded Developer ID Application `.p12`.
- `MACOS_CERTIFICATE_PASSWORD`: password for the `.p12`.
- `DEVELOPER_ID_APPLICATION`: signing identity name.
- `APPLE_ID`: Apple ID for notarization.
- `APPLE_TEAM_ID`: Apple Developer Team ID.
- `APPLE_APP_SPECIFIC_PASSWORD`: app-specific password.

If these secrets are absent, the workflow still publishes an unsigned DMG.
