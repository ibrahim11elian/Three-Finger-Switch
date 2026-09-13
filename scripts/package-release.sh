#!/bin/zsh
set -euo pipefail

project_dir="${0:A:h:h}"
app_dir="$project_dir/outputs/Three Finger Switch.app"

if [[ -z "${CODESIGN_IDENTITY:-}" || "$CODESIGN_IDENTITY" == "-" ]]; then
  echo "CODESIGN_IDENTITY must name a Developer ID Application certificate." >&2
  exit 1
fi

ARCHS="${ARCHS:-arm64 x86_64}" "$project_dir/scripts/build-app.sh" >/dev/null

version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app_dir/Contents/Info.plist")"
archive="$project_dir/outputs/Three-Finger-Switch-$version.zip"
checksum="$archive.sha256"

rm -f "$archive" "$checksum"
ditto -c -k --keepParent "$app_dir" "$archive"

if [[ -n "${NOTARY_PROFILE:-}" ]]; then
  xcrun notarytool submit "$archive" --keychain-profile "$NOTARY_PROFILE" --wait
elif [[ -n "${APPLE_ID:-}" && -n "${APPLE_TEAM_ID:-}" && -n "${APPLE_APP_SPECIFIC_PASSWORD:-}" ]]; then
  xcrun notarytool submit "$archive" \
    --apple-id "$APPLE_ID" \
    --team-id "$APPLE_TEAM_ID" \
    --password "$APPLE_APP_SPECIFIC_PASSWORD" \
    --wait
else
  echo "Set NOTARY_PROFILE, or APPLE_ID, APPLE_TEAM_ID, and APPLE_APP_SPECIFIC_PASSWORD." >&2
  exit 1
fi

xcrun stapler staple "$app_dir"
xcrun stapler validate "$app_dir"

rm -f "$archive"
ditto -c -k --keepParent "$app_dir" "$archive"
(cd "$project_dir/outputs" && shasum -a 256 "${archive:t}") > "$checksum"
spctl --assess --type execute --verbose=2 "$app_dir"

echo "$archive"
echo "$checksum"
