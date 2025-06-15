#!/bin/bash
set -e

# Ensure we're using bash
if [ -z "$BASH_VERSION" ]; then
    exec /bin/bash "$0" "$@"
fi

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Make all .sh files executable
make_scripts_executable() {
    print_section "Making scripts executable"
    find "$SCRIPT_DIR/.." -type f -name "*.sh" -exec chmod +x {} \;
    echo "✅ All .sh files are now executable"
}

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

# Phase 1: Project Setup & Core Configuration
setup_build_environment() {
    echo "Setting up build environment..."
    
    # Source variables from admin panel
    if [ -f "lib/scripts/android/admin_vars.sh" ]; then
        source lib/scripts/android/admin_vars.sh
    else
        echo "Error: admin_vars.sh not found"
        return 1
    fi
    
    # Validate required variables
    if [ -z "$APP_NAME" ] || [ -z "$PKG_NAME" ] || [ -z "$VERSION_NAME" ] || [ -z "$VERSION_CODE" ]; then
        echo "Error: Required variables not set"
        return 1
    fi
    
    # Create necessary directories
    mkdir -p "$ASSETS_DIR"
    mkdir -p "$ANDROID_MIPMAP_DIR"
    mkdir -p "$ANDROID_DRAWABLE_DIR"
    mkdir -p "$ANDROID_VALUES_DIR"
    
    return 0
}

download_splash_assets() {
    echo "Downloading splash assets..."
    
    # Download logo if provided
    if [ -n "$LOGO_URL" ]; then
        curl -L "$LOGO_URL" -o "$ASSETS_DIR/logo.png"
    fi
    
    # Download splash screen if provided
    if [ -n "$SPLASH" ]; then
        curl -L "$SPLASH" -o "$ASSETS_DIR/splash.png"
    fi
    
    # Download splash background if provided
    if [ -n "$SPLASH_BG" ]; then
        curl -L "$SPLASH_BG" -o "$ASSETS_DIR/splash_bg.png"
    fi
    
    return 0
}

generate_launcher_icons() {
    echo "Generating launcher icons..."
    
    # Check if flutter_launcher_icons is in pubspec.yaml
    if ! grep -q "flutter_launcher_icons" pubspec.yaml; then
        echo "Error: flutter_launcher_icons not found in pubspec.yaml"
        return 1
    fi
    
    # Run icon generation
    flutter pub run flutter_launcher_icons:main
    
    # Verify icons were generated
    local icon_paths=(
        "$ANDROID_MIPMAP_DIR-hdpi/ic_launcher.png"
        "$ANDROID_MIPMAP_DIR-mdpi/ic_launcher.png"
        "$ANDROID_MIPMAP_DIR-xhdpi/ic_launcher.png"
        "$ANDROID_MIPMAP_DIR-xxhdpi/ic_launcher.png"
        "$ANDROID_MIPMAP_DIR-xxxhdpi/ic_launcher.png"
    )
    
    local missing_icons=0
    for icon_path in "${icon_paths[@]}"; do
        if [ ! -f "$icon_path" ]; then
            echo "Error: Missing icon at $icon_path"
            missing_icons=$((missing_icons + 1))
        fi
    done
    
    if [ $missing_icons -gt 0 ]; then
        echo "Error: $missing_icons icons are missing"
        return 1
    fi
    
    return 0
}

# Phase 2: Conditional Integration (Firebase & Keystore)
setup_firebase() {
    echo "Setting up Firebase configuration..."
    
    # Check if Firebase is required
    if [ "$PUSH_NOTIFY" != "true" ]; then
        echo "Firebase integration not required (PUSH_NOTIFY is false)"
        return 0
    fi
    
    # Check if Firebase config is provided
    if [ -z "$firebase_config_android" ]; then
        echo "Error: Firebase configuration not provided"
        return 1
    fi
    
    # Remove any existing google-services.json
    rm -f "$ANDROID_FIREBASE_CONFIG_PATH"
    
    # Create Firebase config directory
    mkdir -p "$(dirname "$ANDROID_FIREBASE_CONFIG_PATH")"
    
    # Write Firebase config to file
    echo "$firebase_config_android" > "$ANDROID_FIREBASE_CONFIG_PATH"
    
    # Copy to assets if needed
    cp "$ANDROID_FIREBASE_CONFIG_PATH" "$ASSETS_DIR/google-services.json"
    
    # Verify Firebase config was created
    if [ ! -f "$ANDROID_FIREBASE_CONFIG_PATH" ]; then
        echo "Error: Failed to create Firebase configuration file"
        return 1
    fi
    
    echo "Firebase configuration setup completed successfully"
    return 0
}

setup_keystore() {
    echo "Setting up Android keystore..."
    
    # Check if keystore is required
    if [ -z "$KEY_STORE" ]; then
        echo "Keystore not provided, using debug keystore"
        return 0
    fi
    
    # Create keystore directory
    mkdir -p "$(dirname "$ANDROID_KEYSTORE_PATH")"
    
    # Remove any existing keystore
    rm -f "$ANDROID_KEYSTORE_PATH"
    
    # Write keystore to file
    echo "$KEY_STORE" > "$ANDROID_KEYSTORE_PATH"
    
    # Verify keystore was created
    if [ ! -f "$ANDROID_KEYSTORE_PATH" ]; then
        echo "Error: Failed to create keystore file"
        return 1
    fi
    
    # Create key.properties file
    cat > "$ANDROID_KEY_PROPERTIES_PATH" << EOF
storeFile=keystore.jks
storePassword=$CM_KEYSTORE_PASSWORD
keyAlias=$CM_KEY_ALIAS
keyPassword=$CM_KEY_PASSWORD
EOF
    
    echo "Keystore setup completed successfully"
    return 0
}

update_gradle_files() {
    echo "Updating Gradle files..."
    
    # Update build.gradle
    sed -i '' "s/applicationId \".*\"/applicationId \"$PKG_NAME\"/" "$ANDROID_BUILD_GRADLE_PATH"
    sed -i '' "s/versionCode .*/versionCode $VERSION_CODE/" "$ANDROID_BUILD_GRADLE_PATH"
    sed -i '' "s/versionName \".*\"/versionName \"$VERSION_NAME\"/" "$ANDROID_BUILD_GRADLE_PATH"
    
    # Add Firebase dependencies if needed
    if [ "$PUSH_NOTIFY" = "true" ]; then
        if ! grep -q "com.google.firebase" "$ANDROID_BUILD_GRADLE_PATH"; then
            sed -i '' "/dependencies {/a\\
    implementation platform('com.google.firebase:firebase-bom:32.7.0')\\
    implementation 'com.google.firebase:firebase-analytics'\\
    implementation 'com.google.firebase:firebase-messaging'" "$ANDROID_BUILD_GRADLE_PATH"
        fi
    fi
    
    return 0
}

# Phase 3: Verification & Build
verify_requirements() {
    echo "Verifying requirements..."
    
    # Check Flutter environment
    if ! command -v flutter &> /dev/null; then
        echo "Error: Flutter not found"
        return 1
    fi
    
    # Check Android SDK
    if [ -z "$ANDROID_HOME" ]; then
        echo "Error: ANDROID_HOME not set"
        return 1
    fi
    
    # Check Firebase config if needed
    if [ "$PUSH_NOTIFY" = "true" ] && [ ! -f "$ANDROID_FIREBASE_CONFIG_PATH" ]; then
        echo "Error: Firebase config not found"
        return 1
    fi
    
    # Check keystore if provided
    if [ -n "$KEY_STORE" ] && [ ! -f "$ANDROID_KEYSTORE_PATH" ]; then
        echo "Error: Keystore not found"
        return 1
    fi
    
    return 0
}

build_android_app() {
    echo "Building Android app..."
    
    # Clean the project
    flutter clean
    
    # Get dependencies
    flutter pub get
    
    # Build the app
    if [ -n "$KEY_STORE" ]; then
        flutter build apk --release
    else
        flutter build apk --debug
    fi
    
    # Check build result
    if [ $? -ne 0 ]; then
        echo "Error: Build failed"
        return 1
    fi
    
    return 0
}

# Main build process
main() {
    echo "Starting Android build process..."
    
    # Phase 1: Project Setup & Core Configuration
    setup_build_environment || handle_build_error "Failed to setup build environment"
    download_splash_assets || handle_build_error "Failed to download splash assets"
    generate_launcher_icons || handle_build_error "Failed to generate launcher icons"
    
    # Phase 2: Conditional Integration
    setup_firebase || handle_build_error "Failed to setup Firebase"
    setup_keystore || handle_build_error "Failed to setup keystore"
    update_gradle_files || handle_build_error "Failed to update Gradle files"
    
    # Phase 3: Verification & Build
    verify_requirements || handle_build_error "Failed to verify requirements"
    build_android_app || handle_build_error "Failed to build Android app"
    
    # Success
    handle_build_success
}

# Run the main process
main
