#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source download functions
source "$SCRIPT_DIR/download.sh"

# Function to handle errors
handle_error() {
    local exit_code=$1
    local line_number=$2
    echo "❌ Error occurred in $0 at line $line_number (exit code: $exit_code)"
    echo "Failed command: $BASH_COMMAND"
    exit $exit_code
}

# Set error handler
trap 'handle_error $? $LINENO' ERR

# Function to print section headers
print_section() {
    echo "=== $1 ==="
}

# Main build process
print_section "Starting Combined Build Process"

# Setup environment
print_section "Setting up environment"
find "$SCRIPT_DIR" -type f -name "*.sh" -exec chmod +x {} \;

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
create_directory "$ANDROID_ROOT" "Android root"
create_directory "$IOS_ROOT" "iOS root"
create_directory "$ASSETS_DIR" "assets"
create_directory "$TEMP_DIR" "temporary"

# Create Android resource directories
create_directory "$ANDROID_ROOT/app/src/main/res/mipmap" "mipmap resources"
create_directory "$ANDROID_ROOT/app/src/main/res/drawable" "drawable resources"
create_directory "$ANDROID_ROOT/app/src/main/res/values" "values resources"

# Create iOS resource directories
create_directory "$IOS_ROOT/Runner/Assets.xcassets" "iOS assets"
create_directory "$IOS_ROOT/Runner/Base.lproj" "iOS base resources"
create_directory "$IOS_CERTIFICATES_DIR" "iOS certificates"
create_directory "$IOS_PROVISIONING_DIR" "iOS provisioning"

# Create build output directories
create_directory "$(dirname "$APK_OUTPUT_PATH")" "APK output"
create_directory "$(dirname "$AAB_OUTPUT_PATH")" "AAB output"
create_directory "$(dirname "$IPA_OUTPUT_PATH")" "IPA output"

source "$SCRIPT_DIR/export.sh"

# Validate environment
print_section "Validating environment"
bash "$SCRIPT_DIR/validate.sh"

# Configure app details
print_section "Configuring app details"

# Update Android configuration
sed -i '' "s/android:label=\"[^\"]*\"/android:label=\"$APP_NAME\"/" "$ANDROID_MANIFEST_PATH"
sed -i '' "s/applicationId \"[^\"]*\"/applicationId \"$PKG_NAME\"/" "$ANDROID_BUILD_GRADLE_PATH"

# Update iOS configuration
plutil -replace CFBundleName -string "$APP_NAME" "$IOS_INFO_PLIST_PATH"
plutil -replace CFBundleDisplayName -string "$APP_NAME" "$IOS_INFO_PLIST_PATH"
plutil -replace CFBundleIdentifier -string "$BUNDLE_ID" "$IOS_INFO_PLIST_PATH"

# Download and setup app icon
download_app_icon

# Download and setup splash screen
download_splash_assets

# Setup Android keystore
print_section "Setting up Android keystore"
setup_keystore() {
    echo "Setting up keystore..."
    echo "$KEY_STORE" | base64 --decode > "$ANDROID_KEYSTORE_PATH"
    echo "storeFile=$KEYSTORE_FILE" > "$ANDROID_KEY_PROPERTIES_PATH"
    echo "storePassword=$CM_KEYSTORE_PASSWORD" >> "$ANDROID_KEY_PROPERTIES_PATH"
    echo "keyAlias=$CM_KEY_ALIAS" >> "$ANDROID_KEY_PROPERTIES_PATH"
    echo "keyPassword=$CM_KEY_PASSWORD" >> "$ANDROID_KEY_PROPERTIES_PATH"
}
setup_keystore

# Setup iOS certificates
print_section "Setting up iOS certificates"
setup_certificates() {
    echo "Setting up certificates..."
    echo "$CERTIFICATE" | base64 --decode > "$IOS_CERTIFICATES_DIR/certificate.p12"
    echo "$PROVISIONING_PROFILE" | base64 --decode > "$IOS_PROVISIONING_DIR/profile.mobileprovision"
}
setup_certificates

# Setup Firebase
print_section "Setting up Firebase"
download_firebase_config "Android" "$FIREBASE_CONFIG_ANDROID" "$ANDROID_FIREBASE_CONFIG_PATH"
download_firebase_config "iOS" "$FIREBASE_CONFIG_IOS" "$IOS_FIREBASE_CONFIG_PATH"

# Build Android
print_section "Building Android"
build_android() {
    echo "Building Android..."
    flutter build apk --release
    flutter build appbundle --release
}
build_android

# Build iOS
print_section "Building iOS"
build_ios() {
    echo "Building iOS..."
    flutter build ios --release --no-codesign
}
build_ios

# Collect artifacts
print_section "Collecting artifacts"
collect_artifacts() {
    echo "Collecting build artifacts..."
    mkdir -p "$OUTPUT_DIR"
    cp "$APK_OUTPUT_PATH" "$OUTPUT_DIR/"
    cp "$AAB_OUTPUT_PATH" "$OUTPUT_DIR/"
    cp "$IPA_OUTPUT_PATH" "$OUTPUT_DIR/"
}
collect_artifacts

# Revert changes
print_section "Reverting changes"
revert_changes() {
    echo "Reverting project changes..."
    git checkout "$ANDROID_MANIFEST_PATH"
    git checkout "$ANDROID_BUILD_GRADLE_PATH"
    git checkout "$IOS_INFO_PLIST_PATH"
    rm -f "$APP_ICON_PATH"
    rm -f "$SPLASH_IMAGE_PATH"
    rm -f "$SPLASH_BG_PATH"
    rm -f "$PUBSPEC_BACKUP_PATH"
    rm -rf "$ANDROID_MIPMAP_DIR"/*
    rm -rf "$ANDROID_DRAWABLE_DIR"/*
    rm -rf "$IOS_ROOT/Runner/Assets.xcassets"/*
    rm -rf "$IOS_ROOT/Runner/Base.lproj"/*
}
revert_changes

# Send success notification
print_section "Sending build notification"
bash "$SCRIPT_DIR/send_error_email.sh" "Build Complete" "Combined build process completed successfully"

print_section "Combined Build Process Completed" 