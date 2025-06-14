#!/usr/bin/env bash

set -euo pipefail
trap 'echo "❌ Version update failed on line $LINENO"; exit 1' ERR

# Get the script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
PUBSPEC_PATH="$PROJECT_ROOT/pubspec.yaml"

echo "🔁 Starting version update..."

# Generate version name and code
VERSION_NAME="${VERSION_NAME:-1.0.0}"
VERSION_CODE="${VERSION_CODE:-$(date +%Y%m%d%H%M)}"

echo "🔢 VERSION_NAME: $VERSION_NAME"
echo "🔢 VERSION_CODE: $VERSION_CODE"

# Change to project root for file operations
cd "$PROJECT_ROOT"

# ───── pubspec.yaml ─────
echo "🔧 Updating pubspec.yaml..."
if [ -f "$PUBSPEC_PATH" ]; then
  if grep -q "^version: " "$PUBSPEC_PATH"; then
    sed -i'' -e "s/^version: .*/version: ${VERSION_NAME}+${VERSION_CODE}/" "$PUBSPEC_PATH"
  else
    echo "version: ${VERSION_NAME}+${VERSION_CODE}" >> "$PUBSPEC_PATH"
  fi
  echo "✅ pubspec.yaml version updated."
else
  echo "❌ pubspec.yaml not found at $PUBSPEC_PATH"
  echo "📂 Project root contents:"
  ls -la "$PROJECT_ROOT" || echo "Cannot list project root"
  exit 1
fi

# ───── Android build.gradle.kts ─────
BUILD_FILE="android/app/build.gradle.kts"
if [ -f "$BUILD_FILE" ]; then
  echo "🔧 Updating Android version in $BUILD_FILE..."
  sed -i'' -E "s/versionCode\s*=\s*[0-9]+/versionCode = ${VERSION_CODE}/" "$BUILD_FILE"
  sed -i'' -E "s/versionName\s*=\s*\"[^\"]+\"/versionName = \"${VERSION_NAME}\"/" "$BUILD_FILE"
  echo "✅ Android version updated in build.gradle.kts"
else
  echo "❌ Android build.gradle.kts not found at $BUILD_FILE"
  # Check for regular build.gradle file as fallback
  BUILD_FILE_GRADLE="android/app/build.gradle"
  if [ -f "$BUILD_FILE_GRADLE" ]; then
    echo "🔧 Found build.gradle instead, updating Android version..."
    sed -i'' -E "s/versionCode\s*[0-9]+/versionCode ${VERSION_CODE}/" "$BUILD_FILE_GRADLE"
    sed -i'' -E "s/versionName\s*\"[^\"]+\"/versionName \"${VERSION_NAME}\"/" "$BUILD_FILE_GRADLE"
    echo "✅ Android version updated in build.gradle"
  else
    echo "❌ Neither build.gradle.kts nor build.gradle found"
    exit 1
  fi
fi

# ───── iOS project.pbxproj ─────
IOS_PROJECT_FILE="ios/Runner.xcodeproj/project.pbxproj"
if [ -f "$IOS_PROJECT_FILE" ]; then
  echo "🔧 Updating iOS version in $IOS_PROJECT_FILE..."
  sed -i'' -e "s/MARKETING_VERSION = .*;/MARKETING_VERSION = ${VERSION_NAME};/" "$IOS_PROJECT_FILE"
  sed -i'' -e "s/CURRENT_PROJECT_VERSION = .*;/CURRENT_PROJECT_VERSION = ${VERSION_CODE};/" "$IOS_PROJECT_FILE"
  echo "✅ iOS version updated in project.pbxproj"
else
  echo "❌ iOS project file not found at $IOS_PROJECT_FILE"
  exit 1
fi

echo "🎉 Version update completed successfully!"
echo "📋 Summary:"
echo "   - pubspec.yaml: version: ${VERSION_NAME}+${VERSION_CODE}"
echo "   - Android: versionName: ${VERSION_NAME}, versionCode: ${VERSION_CODE}"
echo "   - iOS: MARKETING_VERSION: ${VERSION_NAME}, CURRENT_PROJECT_VERSION: ${VERSION_CODE}"
