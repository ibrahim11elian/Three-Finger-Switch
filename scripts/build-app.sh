#!/bin/zsh
set -euo pipefail

project_dir="${0:A:h:h}"
configuration="${CONFIGURATION:-release}"
output_dir="$project_dir/outputs"
app_dir="$output_dir/Three Finger Switch.app"
signing_identity="${CODESIGN_IDENTITY:--}"

if [[ -n "${APP_VERSION:-}" && ! "$APP_VERSION" =~ '^[0-9]+\.[0-9]+\.[0-9]+$' ]]; then
  echo "APP_VERSION must use the form 2.1.0." >&2
  exit 1
fi
if [[ -n "${BUILD_NUMBER:-}" && ! "$BUILD_NUMBER" =~ '^[0-9]+$' ]]; then
  echo "BUILD_NUMBER must contain digits only." >&2
  exit 1
fi
if [[ -n "${BUNDLE_IDENTIFIER:-}" && ! "$BUNDLE_IDENTIFIER" =~ '^[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+$' ]]; then
  echo "BUNDLE_IDENTIFIER must be a reverse-DNS identifier." >&2
  exit 1
fi

cd "$project_dir"
if [[ -n "${ARCHS:-}" ]]; then
  architecture_binaries=()
  for architecture in ${=ARCHS}; do
    scratch_path="$project_dir/.build/$architecture"
    triple="$architecture-apple-macosx13.0"
    swift build -c "$configuration" --triple "$triple" --scratch-path "$scratch_path"
    binary_dir="$(
      swift build -c "$configuration" --triple "$triple" \
        --scratch-path "$scratch_path" --show-bin-path
    )"
    architecture_binaries+=("$binary_dir/ThreeFingerSwitch")
  done

  if (( ${#architecture_binaries[@]} > 1 )); then
    binary_source="$project_dir/.build/ThreeFingerSwitch-universal"
    lipo -create "${architecture_binaries[@]}" -output "$binary_source"
  else
    binary_source="${architecture_binaries[1]}"
  fi
else
  swift build -c "$configuration"
  binary_dir="$(swift build -c "$configuration" --show-bin-path)"
  binary_source="$binary_dir/ThreeFingerSwitch"
fi

rm -rf "$app_dir"
mkdir -p "$app_dir/Contents/MacOS"
mkdir -p "$app_dir/Contents/Resources"
cp "$binary_source" "$app_dir/Contents/MacOS/ThreeFingerSwitch"
cp "$project_dir/AppResources/Info.plist" "$app_dir/Contents/Info.plist"
cp "$project_dir/AppResources/AppIcon.icns" "$app_dir/Contents/Resources/AppIcon.icns"

if [[ -n "${APP_VERSION:-}" ]]; then
  /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $APP_VERSION" \
    "$app_dir/Contents/Info.plist"
fi
if [[ -n "${BUILD_NUMBER:-}" ]]; then
  /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" \
    "$app_dir/Contents/Info.plist"
fi
if [[ -n "${BUNDLE_IDENTIFIER:-}" ]]; then
  /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $BUNDLE_IDENTIFIER" \
    "$app_dir/Contents/Info.plist"
fi

if [[ "$signing_identity" == "-" ]]; then
  codesign --force --options runtime --sign - "$app_dir"
else
  codesign --force --options runtime --timestamp --sign "$signing_identity" "$app_dir"
fi

codesign --verify --deep --strict --verbose=2 "$app_dir"

echo "$app_dir"
