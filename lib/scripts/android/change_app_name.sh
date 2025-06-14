#!/usr/bin/env bash

set -euo pipefail
trap 'echo "❌ Error on line $LINENO"; exit 1' ERR

# Get the script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
PUBSPEC_PATH="$PROJECT_ROOT/pubspec.yaml"

echo "🚀 Changing app name to: ${APP_NAME:-UnknownApp}"

# Change to project root for file operations
cd "$PROJECT_ROOT"

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

if [ -f "$PUBSPEC_PATH" ]; then
  if grep -q "^version: " "$PUBSPEC_PATH"; then
    sed -i.bak -E "s/^version: .*/version: $VERSION_NAME+$VERSION_CODE/" "$PUBSPEC_PATH"
  else
    echo "version: $VERSION_NAME+$VERSION_CODE" >> "$PUBSPEC_PATH"
  fi
  echo "✅ Version updated in pubspec.yaml"
else
  echo "❌ pubspec.yaml not found at $PUBSPEC_PATH"
  echo "📂 Project root contents:"
  ls -la "$PROJECT_ROOT" || echo "Cannot list project root"
  exit 1
fi

flutter pub get

echo "✅ App name changed and version set successfully."
