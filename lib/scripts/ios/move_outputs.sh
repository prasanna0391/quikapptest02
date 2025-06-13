#!/usr/bin/env bash

set -euo pipefail

echo "📁 Moving iOS build outputs to final location..."

# Check if required environment variables are set
if [ -z "${CM_BUILD_DIR:-}" ]; then
    echo "❌ Error: CM_BUILD_DIR environment variable is not set"
    exit 1
fi

if [ -z "${BUILD_OUTPUT_DIR:-}" ]; then
    echo "❌ Error: BUILD_OUTPUT_DIR environment variable is not set"
    exit 1
fi

if [ -z "${APP_NAME:-}" ]; then
    echo "❌ Error: APP_NAME environment variable is not set"
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
cm_build_dir="$CM_BUILD_DIR"
build_output_dir="$BUILD_OUTPUT_DIR"
app_name="$APP_NAME"
version_name="$VERSION_NAME"
version_code="$VERSION_CODE"

# Create timestamp for output directory
timestamp=$(date +"%Y%m%d_%H%M%S")
output_dir="$build_output_dir/ios_${timestamp}"

echo "📁 Moving build artifacts..."
echo "  Source: $cm_build_dir"
echo "  Destination: $output_dir"
echo "  App: $app_name v$version_name+$version_code"

# Create output directory
mkdir -p "$output_dir"

# Move IPA file
export_path="$cm_build_dir/export"
ipa_file=$(find "$export_path" -name "*.ipa" -type f | head -n 1)

if [ -n "$ipa_file" ] && [ -f "$ipa_file" ]; then
    # Create a descriptive filename
    ipa_filename="${app_name// /_}_v${version_name}_build${version_code}.ipa"
    ipa_filename=$(echo "$ipa_filename" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9._-]//g')
    
    cp "$ipa_file" "$output_dir/$ipa_filename"
    echo "✅ IPA moved: $output_dir/$ipa_filename"
    
    # Set environment variable for email script
    export FINAL_IPA_PATH="$output_dir/$ipa_filename"
    export IPA_SIZE=$(stat -f%z "$output_dir/$ipa_filename" 2>/dev/null || stat -c%s "$output_dir/$ipa_filename" 2>/dev/null || echo "0")
else
    echo "⚠️ No IPA file found to move"
    export FINAL_IPA_PATH=""
    export IPA_SIZE="0"
fi

# Move archive (optional, for debugging)
archive_path="$cm_build_dir/Runner.xcarchive"
if [ -d "$archive_path" ]; then
    cp -r "$archive_path" "$output_dir/"
    echo "✅ Archive moved: $output_dir/Runner.xcarchive"
fi

# Move ExportOptions.plist (for reference)
export_options_plist="$cm_build_dir/ExportOptions.plist"
if [ -f "$export_options_plist" ]; then
    cp "$export_options_plist" "$output_dir/"
    echo "✅ ExportOptions.plist moved: $output_dir/ExportOptions.plist"
fi

# Move provisioning profile (for reference)
profile_path="$cm_build_dir/profile.mobileprovision"
if [ -f "$profile_path" ]; then
    cp "$profile_path" "$output_dir/"
    echo "✅ Provisioning profile moved: $output_dir/profile.mobileprovision"
fi

# Create build info file
build_info_file="$output_dir/build_info.txt"
cat > "$build_info_file" <<EOF
iOS Build Information
=====================

App Name: $app_name
Bundle ID: ${BUNDLE_ID:-unknown}
Version: $version_name+$version_code
Build Date: $(date)
Build Timestamp: $timestamp

Build Configuration:
- iOS Deployment Target: ${IPHONEOS_DEPLOYMENT_TARGET:-unknown}
- Export Method: ${EXPORT_METHOD:-unknown}
- Team ID: ${APPLE_TEAM_ID:-unknown}

Features Enabled:
- Push Notifications: ${PUSH_NOTIFY:-false}
- Camera: ${IS_CAMERA:-false}
- Location: ${IS_LOCATION:-false}
- Microphone: ${IS_MIC:-false}
- Contacts: ${IS_CONTACT:-false}
- Calendar: ${IS_CALENDAR:-false}
- Photo Library: ${IS_PHOTO_LIBRARY:-false}
- Biometric: ${IS_BIOMETRIC:-false}

Build Artifacts:
- IPA File: ${FINAL_IPA_PATH:-not found}
- Archive: $output_dir/Runner.xcarchive
- Export Options: $output_dir/ExportOptions.plist
- Provisioning Profile: $output_dir/profile.mobileprovision

Build completed successfully!
EOF

echo "✅ Build info created: $build_info_file"

# Display final output summary
echo ""
echo "📊 Build Output Summary:"
echo "========================"
echo "Output Directory: $output_dir"
echo "IPA File: ${FINAL_IPA_PATH:-not found}"
if [ -n "${FINAL_IPA_PATH:-}" ] && [ -f "${FINAL_IPA_PATH:-}" ]; then
    echo "IPA Size: $(du -h "${FINAL_IPA_PATH:-}" | cut -f1)"
fi
echo "Archive: $output_dir/Runner.xcarchive"
echo "Build Info: $build_info_file"
echo ""

# Set environment variables for email script
export BUILD_OUTPUT_DIRECTORY="$output_dir"
export BUILD_TIMESTAMP="$timestamp"

echo "✅ iOS build outputs moved successfully" 