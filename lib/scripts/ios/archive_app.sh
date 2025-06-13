#!/usr/bin/env bash

set -euo pipefail

echo "🏗️ Archiving iOS app..."

# Check if required environment variables are set
if [ -z "${CM_BUILD_DIR:-}" ]; then
    echo "❌ Error: CM_BUILD_DIR environment variable is not set"
    exit 1
fi

if [ -z "${XCODE_WORKSPACE:-}" ]; then
    echo "❌ Error: XCODE_WORKSPACE environment variable is not set"
    exit 1
fi

if [ -z "${XCODE_SCHEME:-}" ]; then
    echo "❌ Error: XCODE_SCHEME environment variable is not set"
    exit 1
fi

if [ -z "${XCODE_CONFIGURATION:-}" ]; then
    echo "❌ Error: XCODE_CONFIGURATION environment variable is not set"
    exit 1
fi

# Set local variables
cm_build_dir="$CM_BUILD_DIR"
workspace="$XCODE_WORKSPACE"
scheme="$XCODE_SCHEME"
configuration="$XCODE_CONFIGURATION"
archive_path="$cm_build_dir/Runner.xcarchive"

echo "🏗️ Archiving the app..."
echo "  Workspace: $workspace"
echo "  Scheme: $scheme"
echo "  Configuration: $configuration"
echo "  Archive Path: $archive_path"

cd ios

# Check if workspace exists
if [ ! -d "$workspace" ]; then
    echo "❌ Error: Xcode workspace not found at $workspace"
    exit 1
fi

# Create archive directory if it doesn't exist
mkdir -p "$(dirname "$archive_path")"

# Archive the app using xcodebuild
echo "🔨 Running xcodebuild archive..."
if ! xcodebuild -workspace "$workspace" \
    -scheme "$scheme" \
    -configuration "$configuration" \
    -archivePath "$archive_path" \
    -sdk iphoneos \
    -destination 'generic/platform=iOS' \
    -allowProvisioningUpdates \
    archive; then
    echo "❌ Xcode archive failed"
    echo ""
    echo "Possible reasons:"
    echo "1. Code signing issues (certificate, provisioning profile, or entitlements)"
    echo "2. Missing dependencies or CocoaPods not properly installed"
    echo "3. Xcode project configuration issues"
    echo "4. iOS deployment target compatibility issues"
    echo "5. Missing required capabilities or entitlements"
    exit 1
fi

cd ..

# Verify archive was created
if [ ! -d "$archive_path" ]; then
    echo "❌ Archive was not created at expected location: $archive_path"
    exit 1
fi

echo "✅ Archive created successfully at $archive_path"

# Display archive information
echo ""
echo "📊 Archive Information:"
echo "  Path: $archive_path"
echo "  Size: $(du -sh "$archive_path" | cut -f1)"
echo "  Created: $(stat -f "%Sm" "$archive_path" 2>/dev/null || stat -c "%y" "$archive_path" 2>/dev/null || echo "unknown")"
echo ""

echo "✅ iOS app archiving completed successfully" 