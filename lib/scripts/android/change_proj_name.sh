#!/usr/bin/env bash
set -euo pipefail
trap 'echo "❌ Error on line $LINENO"; exit 1' ERR

# Get the script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
PUBSPEC_PATH="$PROJECT_ROOT/pubspec.yaml"

echo "App Name: $APP_NAME"

# 2️⃣ Sanitize: lowercase, remove special chars, replace spaces with underscores
SANITIZED_NAME=$(echo "$APP_NAME" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9 ' | tr ' ' '_')
echo "Sanitized app/project name: $SANITIZED_NAME"

# 3️⃣ Extract old name from pubspec.yaml
OLD_NAME_LINE=$(grep '^name: ' "$PUBSPEC_PATH" || true)
if [ -z "$OLD_NAME_LINE" ]; then
  echo "❌ Could not find 'name:' in $PUBSPEC_PATH"
  echo "📁 Checking if pubspec.yaml exists..."
  if [ -f "$PUBSPEC_PATH" ]; then
    echo "✅ pubspec.yaml exists at $PUBSPEC_PATH"
    echo "📋 First few lines of pubspec.yaml:"
    head -10 "$PUBSPEC_PATH" || echo "Cannot read pubspec.yaml"
  else
    echo "❌ pubspec.yaml not found at $PUBSPEC_PATH"
    echo "📂 Project root contents:"
    ls -la "$PROJECT_ROOT" || echo "Cannot list project root"
  fi
  exit 1
fi

OLD_NAME=$(echo "$OLD_NAME_LINE" | cut -d ' ' -f2)
echo "🔁 Renaming project from '$OLD_NAME' to '$SANITIZED_NAME'..."

# Change to project root for file operations
cd "$PROJECT_ROOT"

# Update pubspec.yaml project name
sed -i.bak "s/^name: .*/name: $SANITIZED_NAME/" "$PUBSPEC_PATH"

# Update Dart package imports in lib/
echo "🔄 Updating Dart package imports..."
if [ -d "lib/" ]; then
  grep -rl "package:$OLD_NAME" lib/ | xargs sed -i.bak "s/package:$OLD_NAME/package:$SANITIZED_NAME/g" || echo "⚠️ No imports to update or error"
else
  echo "⚠️ lib/ directory not found"
fi

# iOS: Update CFBundleName in Info.plist
if [ -f ios/Runner/Info.plist ]; then
  echo "🛠️ Updating iOS CFBundleName..."
  plutil -replace CFBundleName -string "$APP_NAME" ios/Runner/Info.plist
else
  echo "⚠️ ios/Runner/Info.plist not found, skipping CFBundleName update"
fi

# Clean build and get packages
flutter clean
flutter pub get

echo "✅ Project renamed to '$SANITIZED_NAME'"
echo "🚀 iOS CFBundleName set to '$APP_NAME'"
