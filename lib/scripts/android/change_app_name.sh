#!/usr/bin/env bash

set -euo pipefail
trap 'echo "❌ Error on line $LINENO"; exit 1' ERR

echo "🚀 Changing app name to: ${APP_NAME:-UnknownApp}"

if [ -z "${APP_NAME:-}" ]; then
  echo "⚠️ APP_NAME is not set. Skipping app rename."
else
  flutter pub run rename setAppName --value "$APP_NAME"
fi

# Default versions if not set
DEFAULT_VERSION_NAME="1.0.0"
DEFAULT_VERSION_CODE="100"

VERSION_NAME="${VERSION_NAME:-$DEFAULT_VERSION_NAME}"
VERSION_CODE="${VERSION_CODE:-$DEFAULT_VERSION_CODE}"

echo "🔢 VERSION_NAME: $VERSION_NAME"
echo "🔢 VERSION_CODE: $VERSION_CODE"

echo "🔧 Ensuring valid version in pubspec.yaml: $VERSION_NAME+$VERSION_CODE"

PUBSPEC_FILE="pubspec.yaml"

if [ -f "$PUBSPEC_FILE" ]; then
  if grep -q "^version: " "$PUBSPEC_FILE"; then
    sed -i.bak -E "s/^version: .*/version: $VERSION_NAME+$VERSION_CODE/" "$PUBSPEC_FILE"
  else
    echo "version: $VERSION_NAME+$VERSION_CODE" >> "$PUBSPEC_FILE"
  fi
else
  echo "❌ $PUBSPEC_FILE not found. Cannot set version."
  exit 1
fi

flutter pub get

echo "✅ App name changed and version set successfully."
