#!/bin/bash
set -e

# Ensure we're using bash
if [ -z "$BASH_VERSION" ]; then
    exec /bin/bash "$0" "$@"
fi

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Print section header
print_section() {
    echo "=== $1 ==="
}

# Source the admin variables
if [ -f "${SCRIPT_DIR}/admin_vars.sh" ]; then
    source "${SCRIPT_DIR}/admin_vars.sh"
else
    echo "Error: admin_vars.sh not found in ${SCRIPT_DIR}"
    exit 1
fi

# Source download functions
if [ -f "${SCRIPT_DIR}/../combined/download.sh" ]; then
    source "${SCRIPT_DIR}/../combined/download.sh"
else
    echo "Error: download.sh not found in ${SCRIPT_DIR}/../combined"
    exit 1
fi

# Load the email configuration
if [ -f "${SCRIPT_DIR}/email_config.sh" ]; then
    source "${SCRIPT_DIR}/email_config.sh"
else
    echo "Error: email_config.sh not found in ${SCRIPT_DIR}"
    exit 1
fi

# Function to setup build environment
setup_build_environment() {
    print_section "Setting up build environment"
    
    # Set up Java environment
    export JAVA_HOME="/opt/homebrew/opt/openjdk@17"
    export PATH="$JAVA_HOME/bin:$PATH"
    
    # Set up Android environment
    export ANDROID_HOME="$HOME/Library/Android/sdk"
    export PATH="$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools:$PATH"
    
    # Set up Flutter environment
    export FLUTTER_ROOT="/opt/homebrew/bin/flutter"
    export PATH="$FLUTTER_ROOT/bin:$PATH"
    
    # Verify environment
    if ! command -v java &> /dev/null; then
        echo "❌ Java not found"
        return 1
    fi
    
    if ! command -v adb &> /dev/null; then
        echo "❌ Android SDK not found"
        return 1
    fi
    
    if ! command -v flutter &> /dev/null; then
        echo "❌ Flutter not found"
        return 1
    fi
    
    echo "✅ Build environment setup complete"
    return 0
}

# Function to generate launcher icons
generate_launcher_icons() {
    print_section "Generating launcher icons"
    
    # Check if flutter_launcher_icons package is available
    if ! flutter pub get; then
        echo "❌ Failed to get Flutter dependencies"
        return 1
    fi
    
    # Check if flutter_launcher_icons is in pubspec.yaml
    if ! grep -q "flutter_launcher_icons" "pubspec.yaml"; then
        echo "❌ flutter_launcher_icons not found in pubspec.yaml"
        return 1
    fi
    
    # Generate icons
    if ! flutter pub run flutter_launcher_icons; then
        echo "❌ Failed to generate launcher icons"
        return 1
    fi
    
    # Verify icons were generated
    local icon_paths=(
        "$ANDROID_ROOT/app/src/main/res/mipmap-hdpi/ic_launcher.png"
        "$ANDROID_ROOT/app/src/main/res/mipmap-mdpi/ic_launcher.png"
        "$ANDROID_ROOT/app/src/main/res/mipmap-xhdpi/ic_launcher.png"
        "$ANDROID_ROOT/app/src/main/res/mipmap-xxhdpi/ic_launcher.png"
        "$ANDROID_ROOT/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png"
    )
    
    local missing_icons=0
    for icon_path in "${icon_paths[@]}"; do
        if [ ! -f "$icon_path" ]; then
            echo "❌ Launcher icon not found at: $icon_path"
            missing_icons=$((missing_icons + 1))
        fi
    done
    
    if [ $missing_icons -gt 0 ]; then
        echo "❌ $missing_icons launcher icons are missing"
        return 1
    fi
    
    echo "✅ Launcher icons generated successfully"
    return 0
}

# Error handling function
handle_error() {
    local error_message="$1"
    local error_details="$2"
    
    print_section "Build failed"
    print_section "Sending error notification"
    send_error_notification "$error_message" "$error_details"
    exit 1
}

# Function to handle build success
handle_build_success() {
    print_section "Build completed successfully"
    print_section "Sending success notification"
    send_success_notification
    exit 0
}

# Function to handle build error
handle_build_error() {
    local error_message="$1"
    local error_details="$2"
    
    print_section "Build failed"
    print_section "Sending error notification"
    send_error_notification "$error_message" "$error_details"
    exit 1
}

# Main build process
print_section "Starting Android Build Process"

# Setup environment
print_section "Setting up environment"
find lib/scripts -type f -name "*.sh" -exec chmod +x {} \;

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

# Update the build process to use error handling
if ! setup_build_environment; then
    handle_build_error "Failed to set up build environment" "Could not initialize build environment. Please check the build logs for details."
fi

if ! download_splash_assets; then
    handle_build_error "Failed to download splash assets" "Could not download splash screen assets. Please check your internet connection and try again."
fi

if ! generate_launcher_icons; then
    handle_build_error "Failed to generate launcher icons" "Could not generate app launcher icons. Please check the icon configuration and try again."
fi

if ! setup_keystore; then
    handle_build_error "Failed to set up keystore" "Could not set up the keystore for signing. Please check your keystore configuration."
fi

if ! setup_firebase; then
    handle_build_error "Failed to set up Firebase" "Could not configure Firebase. Please check your Firebase configuration."
fi

if ! build_android_app; then
    handle_build_error "Failed to build Android app" "The Android build process failed. Please check the build logs for details."
fi

# If we reach here, the build was successful
handle_build_success

print_section "Android Build Process Completed"
