#!/usr/bin/env bash

set -euo pipefail

echo "📄 Creating iOS app entitlements file..."

# Check if required environment variables are set
if [ -z "${APPLE_TEAM_ID:-}" ]; then
    echo "❌ Error: APPLE_TEAM_ID environment variable is not set"
    exit 1
fi

if [ -z "${BUNDLE_ID:-}" ]; then
    echo "❌ Error: BUNDLE_ID environment variable is not set"
    exit 1
fi

# Set local variables
apple_team_id="$APPLE_TEAM_ID"
bundle_id="$BUNDLE_ID"

# Determine if we're using a development or production profile
# Default to development profile based on the current profile analysis
is_development_profile="${IS_DEVELOPMENT_PROFILE:-true}"
is_production_profile="${IS_PRODUCTION_PROFILE:-false}"

# Set get-task-allow based on profile type
if [ "$is_development_profile" = "true" ]; then
    get_task_allow="true"
    aps_environment="development"
    echo "🔧 Using development profile settings (get-task-allow=true, aps-environment=development)"
else
    get_task_allow="false"
    aps_environment="production"
    echo "🔧 Using production profile settings (get-task-allow=false, aps-environment=production)"
fi

echo "📄 Ensuring entitlements file exists..."
mkdir -p ios/Runner
ENTITLEMENTS_FILE="ios/Runner/Runner.entitlements"

# Create entitlements file with basic permissions
cat > "$ENTITLEMENTS_FILE" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <false/>
    <key>com.apple.security.network.client</key>
    <true/>
    <key>com.apple.developer.team-identifier</key>
    <string>${apple_team_id}</string>
    <key>keychain-access-groups</key>
    <array>
        <string>${apple_team_id}.*</string>
    </array>
    <key>get-task-allow</key>
    <${get_task_allow}/>
    <key>application-identifier</key>
    <string>${apple_team_id}.${bundle_id}</string>
EOF

# Add conditional entitlements based on environment variables
if [ "${PUSH_NOTIFY:-false}" = "true" ]; then
    echo "    <key>aps-environment</key>" >> "$ENTITLEMENTS_FILE"
    echo "    <string>${aps_environment}</string>" >> "$ENTITLEMENTS_FILE"
fi

if [ "${IS_CAMERA:-false}" = "true" ]; then
    echo "    <key>com.apple.security.device.camera</key>" >> "$ENTITLEMENTS_FILE"
    echo "    <true/>" >> "$ENTITLEMENTS_FILE"
fi

if [ "${IS_MIC:-false}" = "true" ]; then
    echo "    <key>com.apple.security.device.microphone</key>" >> "$ENTITLEMENTS_FILE"
    echo "    <true/>" >> "$ENTITLEMENTS_FILE"
fi

if [ "${IS_LOCATION:-false}" = "true" ]; then
    echo "    <key>com.apple.security.personal-information.location</key>" >> "$ENTITLEMENTS_FILE"
    echo "    <true/>" >> "$ENTITLEMENTS_FILE"
fi

if [ "${IS_CONTACT:-false}" = "true" ]; then
    echo "    <key>com.apple.security.personal-information.addressbook</key>" >> "$ENTITLEMENTS_FILE"
    echo "    <true/>" >> "$ENTITLEMENTS_FILE"
fi

if [ "${IS_CALENDAR:-false}" = "true" ]; then
    echo "    <key>com.apple.security.personal-information.calendars</key>" >> "$ENTITLEMENTS_FILE"
    echo "    <true/>" >> "$ENTITLEMENTS_FILE"
fi

if [ "${IS_PHOTO_LIBRARY:-false}" = "true" ]; then
    echo "    <key>com.apple.security.assets.user-selected.read-only</key>" >> "$ENTITLEMENTS_FILE"
    echo "    <true/>" >> "$ENTITLEMENTS_FILE"
fi

if [ "${IS_PHOTO_LIBRARY_ADD:-false}" = "true" ]; then
    echo "    <key>com.apple.security.assets.user-selected.read-write</key>" >> "$ENTITLEMENTS_FILE"
    echo "    <true/>" >> "$ENTITLEMENTS_FILE"
fi

if [ "${IS_BIOMETRIC:-false}" = "true" ] || [ "${IS_FACE_ID:-false}" = "true" ] || [ "${IS_TOUCH_ID:-false}" = "true" ]; then
    echo "    <key>com.apple.developer.authentication-services.autofill-credential-provider</key>" >> "$ENTITLEMENTS_FILE"
    echo "    <true/>" >> "$ENTITLEMENTS_FILE"
fi

# Close the plist
cat >> "$ENTITLEMENTS_FILE" <<EOF
</dict>
</plist>
EOF

# Validate entitlements file
if ! plutil -lint "$ENTITLEMENTS_FILE" > /dev/null; then
    echo "❌ Entitlements file has a syntax error: $ENTITLEMENTS_FILE"
    exit 1
fi

echo "✅ Entitlements file created and validated: $ENTITLEMENTS_FILE"

# Display entitlements summary
echo ""
echo "📋 Entitlements Summary:"
echo "  Team ID: $apple_team_id"
echo "  Bundle ID: $bundle_id"
echo "  Profile Type: $([ "$is_development_profile" = "true" ] && echo "Development" || echo "Production")"
echo "  get-task-allow: $get_task_allow"
echo "  aps-environment: $aps_environment"
echo "  Push Notifications: ${PUSH_NOTIFY:-false}"
echo "  Camera: ${IS_CAMERA:-false}"
echo "  Microphone: ${IS_MIC:-false}"
echo "  Location: ${IS_LOCATION:-false}"
echo "  Contacts: ${IS_CONTACT:-false}"
echo "  Calendar: ${IS_CALENDAR:-false}"
echo "  Photo Library: ${IS_PHOTO_LIBRARY:-false}"
echo "  Photo Library Add: ${IS_PHOTO_LIBRARY_ADD:-false}"
echo "  Biometric: ${IS_BIOMETRIC:-false}"
echo ""

echo "✅ iOS entitlements file created successfully" 