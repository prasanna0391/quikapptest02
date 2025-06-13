#!/usr/bin/env bash

set -euo pipefail

echo "🧹 Performing final iOS build cleanup..."

# Check if required environment variables are set
if [ -z "${CM_BUILD_DIR:-}" ]; then
    echo "❌ Error: CM_BUILD_DIR environment variable is not set"
    exit 1
fi

# Set local variables
cm_build_dir="$CM_BUILD_DIR"

echo "🧹 Cleaning up temporary files and build artifacts..."

# Remove temporary profile plist
if [ -f "$cm_build_dir/profile.plist" ]; then
    rm "$cm_build_dir/profile.plist"
    echo "🧹 Removed temporary profile plist file."
fi

# Remove temporary code signing env file (if it was created)
if [ -f "$cm_build_dir/code_signing_env.sh" ]; then
    rm "$cm_build_dir/code_signing_env.sh"
    echo "🧹 Removed temporary code signing env file."
fi

# Remove downloaded certificate and key files (if they exist)
if [ -f "$cm_build_dir/certificate.cer" ]; then
    rm "$cm_build_dir/certificate.cer"
    echo "🧹 Removed downloaded certificate file."
fi

if [ -f "$cm_build_dir/private.key" ]; then
    rm "$cm_build_dir/private.key"
    echo "🧹 Removed downloaded private key file."
fi

# Remove generated .p12 file
if [ -f "$cm_build_dir/generated_certificate.p12" ]; then
    rm "$cm_build_dir/generated_certificate.p12"
    echo "🧹 Removed generated .p12 file."
fi

# Remove downloaded provisioning profile (if not using CM's upload)
if [ -f "$cm_build_dir/profile.mobileprovision" ]; then
    rm "$cm_build_dir/profile.mobileprovision"
    echo "🧹 Removed downloaded provisioning profile file."
fi

# Remove ExportOptions.plist
if [ -f "$cm_build_dir/ExportOptions.plist" ]; then
    rm "$cm_build_dir/ExportOptions.plist"
    echo "🧹 Removed ExportOptions.plist file."
fi

# Remove temporary public key files (if they exist from previous runs)
rm -f "$cm_build_dir/cert_pubkey.pem" "$cm_build_dir/key_pubkey.pem" 2>/dev/null || true

# Clean up CocoaPods cache (optional)
if command -v pod >/dev/null 2>&1; then
    echo "🧹 Cleaning CocoaPods cache..."
    pod cache clean --all >/dev/null 2>&1 || true
    echo "🧹 CocoaPods cache cleaned."
fi

# Clean up Flutter build cache (optional)
if command -v flutter >/dev/null 2>&1; then
    echo "🧹 Cleaning Flutter build cache..."
    flutter clean >/dev/null 2>&1 || true
    echo "🧹 Flutter build cache cleaned."
fi

# Remove temporary build directories (keep only the final output)
if [ -d "$cm_build_dir/export" ]; then
    # Keep the export directory as it contains the final IPA
    echo "🧹 Keeping export directory with final IPA."
fi

# Clean up any temporary files in the project root
find . -name "*.bak" -delete 2>/dev/null || true
find . -name "*.tmp" -delete 2>/dev/null || true

echo "✅ Final cleanup complete."

# Display cleanup summary
echo ""
echo "📊 Cleanup Summary:"
echo "==================="
echo "✅ Removed temporary certificate files"
echo "✅ Removed temporary profile files"
echo "✅ Removed temporary configuration files"
echo "✅ Cleaned CocoaPods cache"
echo "✅ Cleaned Flutter build cache"
echo "✅ Removed backup files"
echo ""

echo "✅ iOS build cleanup completed successfully" 