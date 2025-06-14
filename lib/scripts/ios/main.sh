#!/bin/bash
set -e

# Source download functions
source lib/scripts/combined/download.sh

# Error handling function
handle_error() {
    local exit_code=$1
    local line_number=$2
    echo "❌ Error occurred in $0 at line $line_number (exit code: $exit_code)"
    echo "Failed command: $BASH_COMMAND"
    exit $exit_code
}

# Set error handler
trap 'handle_error $? $LINENO' ERR

# Print section header
print_section() {
    echo "=== $1 ==="
}

# Main build process
print_section "Starting iOS Build Process"

# Setup environment
print_section "Setting up environment"
find lib/scripts -type f -name "*.sh" -exec chmod +x {} \;

# Load admin variables
if [ -f "$(dirname "$0")/admin_vars.sh" ]; then
    source "$(dirname "$0")/admin_vars.sh"
else
    echo "❌ admin_vars.sh not found"
    exit 1
fi

# Ensure CM_BUILD_DIR is set
if [ -z "$CM_BUILD_DIR" ]; then
    CM_BUILD_DIR="$PWD"
    echo "CM_BUILD_DIR not set, using current directory: $CM_BUILD_DIR"
fi

# Create required directories with validation
print_section "Creating required directories"
create_directory() {
    local dir="$1"
    local desc="$2"
    echo "Creating $desc directory: $dir"
    if ! mkdir -p "$dir"; then
        echo "❌ Failed to create $desc directory: $dir"
        exit 1
    fi
    if [ ! -d "$dir" ]; then
        echo "❌ Directory not created: $dir"
        exit 1
    fi
    echo "✅ Created $desc directory: $dir"
}

# Create main directories
create_directory "$CM_BUILD_DIR" "build root"
create_directory "$OUTPUT_DIR" "output"
create_directory "$IOS_ROOT" "iOS root"
create_directory "$ASSETS_DIR" "assets"
create_directory "$TEMP_DIR" "temporary"

# Create iOS resource directories
create_directory "$IOS_ROOT/Runner/Assets.xcassets" "iOS assets"
create_directory "$IOS_ROOT/Runner/Base.lproj" "iOS base resources"
create_directory "$IOS_CERTIFICATES_DIR" "iOS certificates"
create_directory "$IOS_PROVISIONING_DIR" "iOS provisioning"

# Create build output directories
create_directory "$(dirname "$IPA_OUTPUT_PATH")" "IPA output"

source lib/scripts/combined/export.sh

# Validate environment
print_section "Validating environment"
bash lib/scripts/combined/validate.sh

# Configure app details
print_section "Configuring app details"
# Update app name in iOS
plutil -replace CFBundleName -string "$APP_NAME" "$IOS_INFO_PLIST_PATH"
plutil -replace CFBundleDisplayName -string "$APP_NAME" "$IOS_INFO_PLIST_PATH"

# Update bundle identifier in iOS
plutil -replace CFBundleIdentifier -string "$BUNDLE_ID" "$IOS_INFO_PLIST_PATH"

# Download and setup app icon
download_app_icon

# Download and setup splash screen
download_splash_assets

# Setup certificates
print_section "Setting up certificates"
setup_certificates() {
    echo "Setting up certificates..."
    echo "$CERTIFICATE" | base64 --decode > "$IOS_CERTIFICATES_DIR/certificate.p12"
    echo "$PROVISIONING_PROFILE" | base64 --decode > "$IOS_PROVISIONING_DIR/profile.mobileprovision"
}
setup_certificates

# Setup Firebase
print_section "Setting up Firebase"
download_firebase_config "iOS" "$FIREBASE_CONFIG_IOS" "$IOS_FIREBASE_CONFIG_PATH"

# Build IPA
print_section "Building IPA"
build_ipa() {
    echo "Building IPA..."
    flutter build ios --release --no-codesign
}
build_ipa

# Collect artifacts
print_section "Collecting artifacts"
collect_artifacts() {
    echo "Collecting build artifacts..."
    mkdir -p "$OUTPUT_DIR"
    cp "$IPA_OUTPUT_PATH" "$OUTPUT_DIR/"
}
collect_artifacts

# Revert changes
print_section "Reverting changes"
revert_changes() {
    echo "Reverting project changes..."
    git checkout "$IOS_INFO_PLIST_PATH"
    rm -f "$APP_ICON_PATH"
    rm -f "$SPLASH_IMAGE_PATH"
    rm -f "$SPLASH_BG_PATH"
    rm -f "$PUBSPEC_BACKUP_PATH"
    rm -rf "$IOS_ROOT/Runner/Assets.xcassets"/*
    rm -rf "$IOS_ROOT/Runner/Base.lproj"/*
}
revert_changes

# Send success notification
print_section "Sending build notification"
bash lib/scripts/combined/send_error_email.sh "Build Complete" "iOS build process completed successfully"

print_section "iOS Build Process Completed" 