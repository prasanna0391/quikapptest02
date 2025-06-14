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
print_section "Starting Android Build Process"

# Setup environment
print_section "Setting up environment"
find lib/scripts -type f -name "*.sh" -exec chmod +x {} \;

# Load balance variables first
print_section "Loading balance variables"
source "$(dirname "$0")/balance_vars.sh"

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
create_directory "$ASSETS_DIR" "assets"
create_directory "$TEMP_DIR" "temporary"

# Create Android resource directories
create_directory "$ANDROID_ROOT/app/src/main/res/mipmap" "mipmap resources"
create_directory "$ANDROID_ROOT/app/src/main/res/drawable" "drawable resources"
create_directory "$ANDROID_ROOT/app/src/main/res/values" "values resources"

# Create build output directories
create_directory "$(dirname "$APK_OUTPUT_PATH")" "APK output"
create_directory "$(dirname "$AAB_OUTPUT_PATH")" "AAB output"

source lib/scripts/combined/export.sh

# Validate environment
print_section "Validating environment"
bash lib/scripts/combined/validate.sh

# Configure app details
print_section "Configuring app details"
# Update app name in Android
sed -i '' "s/android:label=\"[^\"]*\"/android:label=\"$APP_NAME\"/" "$ANDROID_MANIFEST_PATH"

# Update package name in Android
sed -i '' "s/applicationId \"[^\"]*\"/applicationId \"$PKG_NAME\"/" "$ANDROID_BUILD_GRADLE_PATH"

# Download and setup app icon
download_app_icon

# Download and setup splash screen
download_splash_assets

# Setup local properties
print_section "Setting up local properties"
setup_local_properties() {
    echo "Creating local.properties files..."
    echo "sdk.dir=$ANDROID_HOME" > "$ANDROID_LOCAL_PROPERTIES_PATH"
    echo "flutter.sdk=$FLUTTER_ROOT" >> "$ANDROID_LOCAL_PROPERTIES_PATH"
    echo "flutter.buildMode=release" >> "$ANDROID_LOCAL_PROPERTIES_PATH"
    echo "flutter.versionName=$VERSION_NAME" >> "$ANDROID_LOCAL_PROPERTIES_PATH"
    echo "flutter.versionCode=$VERSION_CODE" >> "$ANDROID_LOCAL_PROPERTIES_PATH"
}
setup_local_properties

# Setup Gradle wrapper
print_section "Setting up Gradle wrapper"
setup_gradle_wrapper() {
    echo "Setting up Gradle wrapper..."
    mkdir -p "$GRADLE_WRAPPER_DIR"
    download_with_retry "$GRADLE_WRAPPER_URL" "$GRADLE_WRAPPER_JAR_PATH"
    echo "distributionBase=GRADLE_USER_HOME" > "$GRADLE_WRAPPER_PROPERTIES_PATH"
    echo "distributionPath=wrapper/dists" >> "$GRADLE_WRAPPER_PROPERTIES_PATH"
    echo "distributionUrl=$GRADLE_DISTRIBUTION_URL" >> "$GRADLE_WRAPPER_PROPERTIES_PATH"
    echo "zipStoreBase=GRADLE_USER_HOME" >> "$GRADLE_WRAPPER_PROPERTIES_PATH"
    echo "zipStorePath=wrapper/dists" >> "$GRADLE_WRAPPER_PROPERTIES_PATH"
}
setup_gradle_wrapper

# Setup keystore
print_section "Setting up keystore"
setup_keystore() {
    echo "Setting up keystore..."
    echo "$KEY_STORE" | base64 --decode > "$ANDROID_KEYSTORE_PATH"
    echo "storeFile=$KEYSTORE_FILE" > "$ANDROID_KEY_PROPERTIES_PATH"
    echo "storePassword=$CM_KEYSTORE_PASSWORD" >> "$ANDROID_KEY_PROPERTIES_PATH"
    echo "keyAlias=$CM_KEY_ALIAS" >> "$ANDROID_KEY_PROPERTIES_PATH"
    echo "keyPassword=$CM_KEY_PASSWORD" >> "$ANDROID_KEY_PROPERTIES_PATH"
}
setup_keystore

# Setup Firebase
print_section "Setting up Firebase"
download_firebase_config "Android" "$FIREBASE_CONFIG_ANDROID" "$ANDROID_FIREBASE_CONFIG_PATH"

# Build APK
print_section "Building APK"
build_apk() {
    echo "Building APK..."
    flutter build apk --release
}
build_apk

# Build AAB
print_section "Building AAB"
build_aab() {
    echo "Building AAB..."
    flutter build appbundle --release
}
build_aab

# Collect artifacts
print_section "Collecting artifacts"
collect_artifacts() {
    echo "Collecting build artifacts..."
    mkdir -p "$OUTPUT_DIR"
    cp "$APK_OUTPUT_PATH" "$OUTPUT_DIR/"
    cp "$AAB_OUTPUT_PATH" "$OUTPUT_DIR/"
}
collect_artifacts

# Revert changes
print_section "Reverting changes"
revert_changes() {
    echo "Reverting project changes..."
    git checkout "$ANDROID_MANIFEST_PATH"
    git checkout "$ANDROID_BUILD_GRADLE_PATH"
    rm -f "$APP_ICON_PATH"
    rm -f "$SPLASH_IMAGE_PATH"
    rm -f "$SPLASH_BG_PATH"
    rm -f "$PUBSPEC_BACKUP_PATH"
    rm -rf "$ANDROID_MIPMAP_DIR"/*
    rm -rf "$ANDROID_DRAWABLE_DIR"/*
}
revert_changes

# Send success notification
print_section "Sending build notification"
bash lib/scripts/combined/send_error_email.sh "Build Complete" "Android build process completed successfully"

print_section "Android Build Process Completed"
