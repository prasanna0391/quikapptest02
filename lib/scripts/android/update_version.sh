#!/usr/bin/env bash

set -euo pipefail
trap 'echo "❌ Version update failed on line $LINENO"; exit 1' ERR

echo "🔁 Starting version update..."

# Generate version name and code
VERSION_NAME="${VERSION_NAME:-1.0.0}"
VERSION_CODE="${VERSION_CODE:-$(date +%Y%m%d%H%M)}"

echo "🔢 VERSION_NAME: $VERSION_NAME"
echo "🔢 VERSION_CODE: $VERSION_CODE"

# ───── pubspec.yaml ─────
echo "🔧 Updating pubspec.yaml..."
if grep -q "^version: " pubspec.yaml; then
  sed -i'' -e "s/^version: .*/version: ${VERSION_NAME}+${VERSION_CODE}/" pubspec.yaml
else
  echo "version: ${VERSION_NAME}+${VERSION_CODE}" >> pubspec.yaml
fi
echo "✅ pubspec.yaml version updated."

# ───── Android build.gradle.kts ─────
BUILD_FILE="android/app/build.gradle.kts"
if [ -f "$BUILD_FILE" ]; then
  echo "🔧 Updating Android version in $BUILD_FILE..."
  sed -i'' -E "s/versionCode\s*=\s*[0-9]+/versionCode = ${VERSION_CODE}/" "$BUILD_FILE"
  sed -i'' -E "s/versionName\s*=\s*\"[^\"]+\"/versionName = \"${VERSION_NAME}\"/" "$BUILD_FILE"
  echo "✅ Android version updated in build.gradle.kts"
else
  echo "❌ Android build.gradle.kts not found at $BUILD_FILE"
  exit 1
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
