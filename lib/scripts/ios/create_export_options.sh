#!/usr/bin/env bash

set -euo pipefail

# iOS ExportOptions.plist Generator
# This script creates the ExportOptions.plist file needed for iOS IPA export

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
IOS_DIR="$PROJECT_ROOT/ios"

# Default values
EXPORT_METHOD="${EXPORT_METHOD:-app-store}"
TEAM_ID="${APPLE_TEAM_ID:-}"
BUNDLE_ID="${BUNDLE_ID:-com.example.app}"

# Log function
log_message() {
    local level="$1"
    local message="$2"
    echo "[$level] $message"
}

log_message "INFO" "🛠️ Creating ExportOptions.plist"
log_message "INFO" "📱 Bundle ID: $BUNDLE_ID"
log_message "INFO" "👥 Team ID: $TEAM_ID"
log_message "INFO" "📦 Export Method: $EXPORT_METHOD"

# Ensure iOS directory exists
mkdir -p "$IOS_DIR"

# Create ExportOptions.plist
cat > "$IOS_DIR/ExportOptions.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>$EXPORT_METHOD</string>
    <key>teamID</key>
    <string>$TEAM_ID</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>$BUNDLE_ID</key>
        <string>match AppStore $BUNDLE_ID</string>
    </dict>
    <key>signingStyle</key>
    <string>manual</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>thinning</key>
    <string>&lt;none&gt;</string>
</dict>
</plist>
EOF

if [ -f "$IOS_DIR/ExportOptions.plist" ]; then
    log_message "INFO" "✅ ExportOptions.plist created successfully at $IOS_DIR/ExportOptions.plist"
else
    log_message "ERROR" "❌ Failed to create ExportOptions.plist"
    exit 1
fi

# Make the script executable
chmod +x "$0"

log_message "INFO" "🎉 ExportOptions.plist setup complete" 