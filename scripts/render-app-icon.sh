#!/bin/zsh
set -euo pipefail

project_dir="${0:A:h:h}"
source_icon="$project_dir/AppResources/AppIcon.png"
master_icon="$project_dir/work/AppIcon-master.png"
iconset_dir="$project_dir/work/AppIcon.iconset"

mkdir -p "$project_dir/work"
swift "$project_dir/scripts/render-app-icon.swift" "$master_icon"
sips -z 1024 1024 "$master_icon" --out "$source_icon" >/dev/null

rm -rf "$iconset_dir"
mkdir -p "$iconset_dir"

for entry in \
  "16 icon_16x16.png" \
  "32 icon_16x16@2x.png" \
  "32 icon_32x32.png" \
  "64 icon_32x32@2x.png" \
  "128 icon_128x128.png" \
  "256 icon_128x128@2x.png" \
  "256 icon_256x256.png" \
  "512 icon_256x256@2x.png" \
  "512 icon_512x512.png" \
  "1024 icon_512x512@2x.png"
do
  size="${entry%% *}"
  filename="${entry#* }"
  sips -z "$size" "$size" "$source_icon" --out "$iconset_dir/$filename" >/dev/null
done

iconutil -c icns "$iconset_dir" -o "$project_dir/AppResources/AppIcon.icns"
echo "$project_dir/AppResources/AppIcon.icns"
