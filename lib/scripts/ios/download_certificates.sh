#!/usr/bin/env bash

set -euo pipefail

echo "🔐 Starting iOS code signing file download..."

# Check if required environment variables are set
if [ -z "${CER_URL:-}" ]; then
    echo "❌ Error: CER_URL environment variable is not set"
    exit 1
fi

if [ -z "${KEY_URL:-}" ]; then
    echo "❌ Error: KEY_URL environment variable is not set"
    exit 1
fi

if [ -z "${PROFILE_URL:-}" ]; then
    echo "❌ Error: PROFILE_URL environment variable is not set"
    exit 1
fi

# Check if build directory exists
if [ -z "${CM_BUILD_DIR:-}" ]; then
    echo "❌ Error: CM_BUILD_DIR environment variable is not set"
    exit 1
fi

# Create build directory if it doesn't exist
mkdir -p "$CM_BUILD_DIR"

echo "🔐 iOS Code Signing Requirements:"
echo "1. Distribution Certificate (.cer) and its matching Private Key (.key)"
echo "2. Provisioning Profile (.mobileprovision) matching the App ID and certificate"
echo ""
echo "⚠️ Using certificate from URL: $CER_URL"
echo "⚠️ Using private key from URL: $KEY_URL"
echo "⚠️ Using profile from URL: $PROFILE_URL"
echo ""

# Download certificate file
echo "📥 Downloading certificate from $CER_URL..."
if ! curl -f -L -o "$CERT_CER_PATH" "$CER_URL"; then
    echo "❌ Failed to download certificate (.cer)"
    echo "Please check the CER_URL and ensure it's accessible"
    exit 1
fi

# Verify certificate file
if [ ! -s "$CERT_CER_PATH" ]; then
    echo "❌ Downloaded certificate file is empty"
    exit 1
fi

echo "✅ Certificate downloaded successfully to $CERT_CER_PATH"

# Download private key file
echo "📥 Downloading private key from $KEY_URL..."
if ! curl -f -L -o "$PRIVATE_KEY_PATH" "$KEY_URL"; then
    echo "❌ Failed to download private key (.key)"
    echo "Please check the KEY_URL and ensure it's accessible"
    exit 1
fi

# Verify private key file
if [ ! -s "$PRIVATE_KEY_PATH" ]; then
    echo "❌ Downloaded private key file is empty"
    exit 1
fi

echo "✅ Private key downloaded successfully to $PRIVATE_KEY_PATH"

# Download provisioning profile file
echo "📥 Downloading provisioning profile from $PROFILE_URL..."
if ! curl -f -L -o "$PROFILE_PATH" "$PROFILE_URL"; then
    echo "❌ Failed to download provisioning profile"
    echo "Please check the PROFILE_URL and ensure it's accessible"
    exit 1
fi

# Verify provisioning profile file
if [ ! -s "$PROFILE_PATH" ]; then
    echo "❌ Downloaded provisioning profile file is empty"
    exit 1
fi

echo "✅ Provisioning profile downloaded successfully to $PROFILE_PATH"

# Display file sizes for verification
echo ""
echo "📊 Downloaded Files Summary:"
echo "Certificate (.cer): $(stat -f%z "$CERT_CER_PATH" 2>/dev/null || stat -c%s "$CERT_CER_PATH" 2>/dev/null || echo "unknown") bytes"
echo "Private Key (.key): $(stat -f%z "$PRIVATE_KEY_PATH" 2>/dev/null || stat -c%s "$PRIVATE_KEY_PATH" 2>/dev/null || echo "unknown") bytes"
echo "Provisioning Profile (.mobileprovision): $(stat -f%z "$PROFILE_PATH" 2>/dev/null || stat -c%s "$PROFILE_PATH" 2>/dev/null || echo "unknown") bytes"
echo ""

echo "✅ Successfully downloaded all required iOS code signing files"
echo "📁 Files are located in: $CM_BUILD_DIR" 