#!/usr/bin/env bash

set -euo pipefail

echo "⚙️ Updating iOS project configuration..."

# Check if required environment variables are set
if [ -z "${APP_NAME:-}" ]; then
    echo "❌ Error: APP_NAME environment variable is not set"
    exit 1
fi

if [ -z "${PKG_NAME:-}" ]; then
    echo "❌ Error: PKG_NAME environment variable is not set"
    exit 1
fi

if [ -z "${BUNDLE_ID:-}" ]; then
    echo "❌ Error: BUNDLE_ID environment variable is not set"
    exit 1
fi

if [ -z "${VERSION_NAME:-}" ]; then
    echo "❌ Error: VERSION_NAME environment variable is not set"
    exit 1
fi

if [ -z "${VERSION_CODE:-}" ]; then
    echo "❌ Error: VERSION_CODE environment variable is not set"
    exit 1
fi

# Set local variables
app_name="$APP_NAME"
pkg_name="$PKG_NAME"
bundle_id="$BUNDLE_ID"
version_name="$VERSION_NAME"
version_code="$VERSION_CODE"

echo "*********** App Name & Version ***********"
echo "APP_NAME: $app_name"
echo "ORG_NAME: $ORG_NAME"
echo "WEB_URL: $WEB_URL"
echo "VERSION_NAME: $version_name"
echo "VERSION_CODE: $version_code"
echo "PKG_NAME: $pkg_name"
echo "BUNDLE_ID: $bundle_id"

echo "App Name: $app_name"

# Sanitize app name for project naming
SANITIZED_NAME=$(echo "$app_name" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9 ' | tr ' ' '_')

# Extract old name from pubspec.yaml
OLD_NAME_LINE=$(grep '^name: ' pubspec.yaml)
if [ -z "$OLD_NAME_LINE" ]; then
    echo "❌ Could not find 'name:' in pubspec.yaml. Cannot rename project."
    exit 1
fi
OLD_NAME=$(echo "$OLD_NAME_LINE" | cut -d ' ' -f2)

echo "🔁 Renaming project from '$OLD_NAME' to '$SANITIZED_NAME'..."

# Update pubspec.yaml
sed -i '' "s|^name: .*|name: $SANITIZED_NAME|" pubspec.yaml

# Update Dart imports
echo "🔄 Updating Dart package imports..."
grep -rl "package:$OLD_NAME" lib/ | xargs sed -i '' "s@package:$OLD_NAME@package:$SANITIZED_NAME@g" || true

# iOS: Update CFBundleName in Info.plist
echo "🛠️ Updating iOS CFBundleName..."
plutil -replace CFBundleName -string "$app_name" ios/Runner/Info.plist || true

echo "✅ Project name, Dart imports, and iOS CFBundleName updated."

echo "🔧 Updating iOS bundle identifier..."

# Validate bundle ID format
if [[ ! "$bundle_id" =~ ^[a-zA-Z_][a-zA-Z0-9_]*(\.[a-zA-Z_][a-zA-Z0-9_]*)+$ ]]; then
    echo "❌ ERROR: Invalid bundle identifier: $bundle_id"
    exit 1
fi

echo "✔ Bundle ID: $bundle_id"

echo "────────────── iOS UPDATE ──────────────"
echo "🍏 Updating iOS bundle identifier..."

IOS_PROJECT_FILE="ios/Runner.xcodeproj/project.pbxproj"
if [ -f "$IOS_PROJECT_FILE" ]; then
    sed -i '' "s@PRODUCT_BUNDLE_IDENTIFIER = .*@PRODUCT_BUNDLE_IDENTIFIER = $bundle_id;@g" "$IOS_PROJECT_FILE"
    echo "✅ iOS bundle identifier updated."
else
    echo "❌ iOS project file not found at $IOS_PROJECT_FILE"
    exit 1
fi

echo "✅ App name changed and bundle ID set successfully"

echo "🔢 Updating app version to: $version_name+$version_code"

# Default values
default_version_name="1.0.0"
default_version_code="100"

# Check if VERSION_NAME is empty or not set
if [ -z "$version_name" ]; then
    version_name=$default_version_name
    echo "🔢 Setting DEFAULT_VERSION_NAME: $version_name"
fi

# Check if VERSION_CODE is empty or not set
if [ -z "$version_code" ]; then
    version_code=$default_version_code
    echo "🔢 Setting DEFAULT_VERSION_CODE: $version_code"
fi

echo "🔢 Using version: $version_name+$version_code"

echo "🔧 Ensuring valid version in pubspec.yaml: $version_name+$version_code"
# Replace or add version line in pubspec.yaml
if grep -q "^version: " pubspec.yaml; then
    sed -i.bak -E "s|^version: .*|version: $version_name+$version_code|" pubspec.yaml
else
    # If version line doesn't exist, add it below the name line
    sed -i.bak "/^name: /a\\
  version: $version_name+$version_code" pubspec.yaml
    echo "Added version line to pubspec.yaml"
fi

# Update iOS version in Info.plist
echo "🍏 Updating iOS version in Info.plist..."
plutil -replace CFBundleShortVersionString -string "$version_name" ios/Runner/Info.plist || true
plutil -replace CFBundleVersion -string "$version_code" ios/Runner/Info.plist || true

# Clean up sed backup files
find . -name "*.bak" -delete
echo "✅ App version set successfully"

echo "✅ iOS project configuration updated successfully" 