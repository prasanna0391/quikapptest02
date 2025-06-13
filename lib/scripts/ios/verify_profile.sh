#!/usr/bin/env bash

set -euo pipefail

echo "🔍 Verifying iOS provisioning profile..."

# Check if required environment variables are set
if [ -z "${PROFILE_PATH:-}" ]; then
    echo "❌ Error: PROFILE_PATH environment variable is not set"
    exit 1
fi

if [ -z "${PROFILE_PLIST_PATH:-}" ]; then
    echo "❌ Error: PROFILE_PLIST_PATH environment variable is not set"
    exit 1
fi

if [ -z "${BUNDLE_ID:-}" ]; then
    echo "❌ Error: BUNDLE_ID environment variable is not set"
    exit 1
fi

if [ -z "${APPLE_TEAM_ID:-}" ]; then
    echo "❌ Error: APPLE_TEAM_ID environment variable is not set"
    exit 1
fi

# Check if profile file exists
if [ ! -f "$PROFILE_PATH" ]; then
    echo "❌ Error: Provisioning profile not found at $PROFILE_PATH"
    exit 1
fi

echo "🔍 Verifying provisioning profile: $PROFILE_PATH"

# Check file size
profile_size=$(stat -f%z "$PROFILE_PATH" 2>/dev/null || stat -c%s "$PROFILE_PATH" 2>/dev/null || echo "0")
if [ "$profile_size" -lt 1000 ]; then
    echo "❌ Provisioning profile appears to be too small or corrupted"
    exit 1
fi

# Convert profile to plist for verification
echo "📄 Converting profile to plist format..."
if ! security cms -D -i "$PROFILE_PATH" > "$PROFILE_PLIST_PATH" 2>/dev/null; then
    echo "❌ Failed to read provisioning profile"
    echo "The profile file may be corrupted or in an invalid format"
    exit 1
fi

# Verify profile details
if ! /usr/libexec/PlistBuddy -c "Print :UUID" "$PROFILE_PLIST_PATH" > /dev/null 2>&1; then
    echo "❌ Invalid provisioning profile format"
    exit 1
fi

# Check profile type (Support multiple distribution profile types)
echo "🔍 Checking profile type..."
is_distribution=false

# Check for Enterprise Distribution (ProvisionsAllDevices)
profile_type=$(/usr/libexec/PlistBuddy -c "Print :ProvisionsAllDevices" "$PROFILE_PLIST_PATH" 2>/dev/null || echo "false")
if [ "$profile_type" = "true" ]; then
    echo "✅ Verified as Enterprise Distribution profile"
    is_distribution=true
fi

# Check for App Store Distribution
if ! $is_distribution; then
    profile_type=$(/usr/libexec/PlistBuddy -c "Print :ProvisionsAllDevices" "$PROFILE_PLIST_PATH" 2>/dev/null || echo "false")
    # Check for a common App Store entitlement (e.g., icloud-container-identifiers)
    has_app_store=$(/usr/libexec/PlistBuddy -c "Print :Entitlements:com.apple.developer.icloud-container-identifiers" "$PROFILE_PLIST_PATH" 2>/dev/null || echo "false")
    # Or check for absence of ProvisionedDevices key, which is present in Ad Hoc/Development
    has_provisioned_devices=$(/usr/libexec/PlistBuddy -c "Print :ProvisionedDevices" "$PROFILE_PLIST_PATH" 2>/dev/null || echo "false")

    if [ "$profile_type" = "false" ] && [ "$has_app_store" != "false" ] && [ "$has_provisioned_devices" = "false" ]; then
        echo "✅ Verified as App Store Distribution profile"
        is_distribution=true
    fi
fi

# Check for Ad Hoc Distribution
if ! $is_distribution; then
    has_provisioned_devices=$(/usr/libexec/PlistBuddy -c "Print :ProvisionedDevices" "$PROFILE_PLIST_PATH" 2>/dev/null || echo "false")
    if [ "$has_provisioned_devices" != "false" ]; then
        echo "✅ Verified as Ad Hoc Distribution profile"
        is_distribution=true
    fi
fi

if ! $is_distribution; then
    echo "❌ Profile is not a distribution profile (not Enterprise, App Store, or Ad Hoc)"
    echo "This profile may be a development profile, which is not suitable for distribution builds"
    exit 1
fi

# Check team identifier
echo "🔍 Verifying team identifier..."
profile_team_id=$(/usr/libexec/PlistBuddy -c "Print :TeamIdentifier:0" "$PROFILE_PLIST_PATH" 2>/dev/null)
if [ "$profile_team_id" != "$APPLE_TEAM_ID" ]; then
    echo "❌ Profile team ID ($profile_team_id) does not match expected team ID ($APPLE_TEAM_ID)"
    exit 1
fi

# Check bundle identifier (prefix match for wildcard, exact match otherwise)
echo "🔍 Verifying bundle identifier..."
profile_bundle_id_entitlement=$(/usr/libexec/PlistBuddy -c "Print :Entitlements:application-identifier" "$PROFILE_PLIST_PATH" 2>/dev/null)

expected_app_id_prefix="$APPLE_TEAM_ID."
if [[ "$profile_bundle_id_entitlement" == "$expected_app_id_prefix"* ]]; then
    profile_bundle_id_no_prefix=$(echo "$profile_bundle_id_entitlement" | sed "s/$expected_app_id_prefix//")
    if [ "$profile_bundle_id_no_prefix" != "$BUNDLE_ID" ] && [ "$profile_bundle_id_no_prefix" != "*" ]; then
        echo "❌ Profile bundle ID ($profile_bundle_id_no_prefix) does not match expected bundle ID ($BUNDLE_ID) and is not a wildcard profile"
        exit 1
    fi
else
    echo "❌ Profile application-identifier entitlement ($profile_bundle_id_entitlement) does not match expected Team ID prefix ($expected_app_id_prefix)"
    exit 1
fi

# Check expiration
echo "🔍 Checking profile expiration..."
profile_expiry=$(/usr/libexec/PlistBuddy -c "Print :ExpirationDate" "$PROFILE_PLIST_PATH" 2>/dev/null)
current_date=$(date +%s)
# Note: macOS date command format might differ slightly in CI. Adjust if needed.
profile_expiry_seconds=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$profile_expiry" +%s 2>/dev/null || date -j -f "%a %b %d %H:%M:%S %Z %Y" "$profile_expiry" +%s 2>/dev/null)

if [ -z "$profile_expiry_seconds" ]; then
    echo "❌ Could not parse profile expiration date: $profile_expiry"
    exit 1
fi

if [ "$current_date" -ge "$profile_expiry_seconds" ]; then
    echo "❌ Provisioning profile has expired on $profile_expiry"
    exit 1
fi

# Display profile information
echo ""
echo "📋 Profile Information:"
echo "------------------------"
echo "UUID: $(/usr/libexec/PlistBuddy -c "Print :UUID" "$PROFILE_PLIST_PATH")"
echo "Name: $(/usr/libexec/PlistBuddy -c "Print :Name" "$PROFILE_PLIST_PATH")"
echo "Expiration: $profile_expiry"
echo "Team ID: $profile_team_id"
echo "Bundle ID: $profile_bundle_id_entitlement"
echo "------------------------"

echo "✅ Provisioning profile verification successful"
echo "📄 Profile is valid and ready for use" 