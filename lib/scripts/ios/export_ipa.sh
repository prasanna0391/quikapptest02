#!/usr/bin/env bash

set -euo pipefail

echo "📦 Exporting IPA from archive..."

# Check if required environment variables are set
if [ -z "${CM_BUILD_DIR:-}" ]; then
    echo "❌ Error: CM_BUILD_DIR environment variable is not set"
    exit 1
fi

if [ -z "${EXPORT_METHOD:-}" ]; then
    echo "❌ Error: EXPORT_METHOD environment variable is not set"
    exit 1
fi

if [ -z "${APPLE_TEAM_ID:-}" ]; then
    echo "❌ Error: APPLE_TEAM_ID environment variable is not set"
    exit 1
fi

# Set local variables
cm_build_dir="$CM_BUILD_DIR"
export_method="$EXPORT_METHOD"
apple_team_id="$APPLE_TEAM_ID"
archive_path="$cm_build_dir/Runner.xcarchive"
export_path="$cm_build_dir/export"
export_options_plist="$cm_build_dir/ExportOptions.plist"

echo "📦 Exporting IPA from archive..."
echo "  Archive Path: $archive_path"
echo "  Export Method: $export_method"
echo "  Export Path: $export_path"
echo "  Team ID: $apple_team_id"

# Check if archive exists
if [ ! -d "$archive_path" ]; then
    echo "❌ Error: Archive not found at $archive_path"
    echo "Please ensure the archive step completed successfully"
    exit 1
fi

# Create export directory
mkdir -p "$export_path"

# Create ExportOptions.plist based on export method
echo "📄 Creating ExportOptions.plist for $export_method method..."
cat > "$export_options_plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>$export_method</string>
    <key>provisioningProfiles</key>
    <dict>
        <!-- Provisioning profiles will be handled automatically by xcodebuild -->
    </dict>
    <key>signingCertificate</key>
    <string>Apple Distribution</string>
    <key>signingStyle</key>
    <string>manual</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>teamID</key>
    <string>$apple_team_id</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
    <key>thinning</key>
    <string>&lt;none&gt;</string>
</dict>
</plist>
EOF

# Validate ExportOptions.plist
if ! plutil -lint "$export_options_plist" > /dev/null; then
    echo "❌ ExportOptions.plist has a syntax error: $export_options_plist"
    exit 1
fi
echo "✅ ExportOptions.plist created and validated"

# Export IPA from archive
echo "🔨 Running xcodebuild export..."
if ! xcodebuild -exportArchive \
    -archivePath "$archive_path" \
    -exportOptionsPlist "$export_options_plist" \
    -exportPath "$export_path" \
    -allowProvisioningUpdates; then
    echo "❌ Xcode export failed"
    echo ""
    echo "Possible reasons:"
    echo "1. Code signing issues (certificate or provisioning profile mismatch)"
    echo "2. Export method not compatible with provisioning profile type"
    echo "3. Missing required entitlements or capabilities"
    echo "4. Archive is corrupted or incomplete"
    echo "5. Insufficient disk space for export"
    exit 1
fi

# Find the exported IPA file
ipa_file=$(find "$export_path" -name "*.ipa" -type f | head -n 1)
if [ -z "$ipa_file" ]; then
    echo "❌ No IPA file found in export directory: $export_path"
    echo "Export may have failed or IPA was not created"
    exit 1
fi

echo "✅ IPA exported successfully to: $ipa_file"

# Display IPA information
echo ""
echo "📊 IPA File Information:"
echo "  File: $ipa_file"
echo "  Size: $(stat -f%z "$ipa_file" 2>/dev/null || stat -c%s "$ipa_file" 2>/dev/null || echo "unknown") bytes"
echo "  Created: $(stat -f "%Sm" "$ipa_file" 2>/dev/null || stat -c "%y" "$ipa_file" 2>/dev/null || echo "unknown")"
echo ""

# Set environment variable for other scripts to use
export EXPORTED_IPA_PATH="$ipa_file"

echo "✅ iOS IPA export completed successfully" 