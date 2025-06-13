#!/usr/bin/env bash
set -euo pipefail

# This script scans for Flutter plugins in .pub-cache
# that contain example code using deprecated Android V1 embedding
# and deletes those example folders to prevent build failures.

PUB_CACHE_DIR="${PUB_CACHE_DIR:-$HOME/.pub-cache/hosted/pub.dev}"

echo "🔍 Scanning plugins in $PUB_CACHE_DIR for legacy v1 embedding..."

# Track how many were found/removed
count=0

# Loop through all plugin example dirs
find "$PUB_CACHE_DIR" -type f -path "*/example/android/app/src/main/java/*" -name "*.java" -o -name "*.kt" | while read -r file; do
  if grep -q "io.flutter.app.FlutterActivity" "$file"; then
    plugin_dir=$(echo "$file" | sed 's@\(.*\/example\)/.*@\1@')
    echo "❌ Found V1 embedding in: $file"
    echo "🗑️ Deleting example folder: $plugin_dir"
    rm -rf "$plugin_dir"
    ((count++))
  fi
done

if [[ $count -eq 0 ]]; then
  echo "✅ No plugin examples with legacy V1 embedding found."
else
  echo "✅ Removed $count plugin example folder(s) using Flutter V1 embedding."
  echo "🚮 Please run: flutter clean && flutter pub get && flutter build apk"
fi