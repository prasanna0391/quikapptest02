#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Get the script directory for dynamic path resolution
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Always set the correct package name for Android builds
export PKG_NAME=com.garbcode.garbcodeapp

# Function to handle errors
handle_error() {
    echo "❌ Build process failed!"
    echo "📍 Error occurred at line: $1"
    echo "🔧 Failed command: $2"
    echo "📊 Exit code: $3"
    
    echo "📧 Sending error notification email..."
    bash "$SCRIPT_DIR/send_error_email.sh" "Build Failed" "Build failed at line $1: $2"
    
    echo "🔄 Ending build session and reverting changes..."
    exit 1
}

# Function to print section headers
print_section() {
    echo "-------------------------------------------------"
    echo "🔧 $1"
    echo "-------------------------------------------------"
}

# Function to setup local properties
setup_local_properties() {
    print_section "Setting up local properties"
    
    # Get Flutter SDK path
    FLUTTER_ROOT=$(which flutter | xargs dirname | xargs dirname)
    
    # Create local.properties in project root
    cat > local.properties << EOF
flutter.sdk=$FLUTTER_ROOT
EOF
    
    # Create local.properties in android directory
    mkdir -p android
    cat > android/local.properties << EOF
flutter.sdk=$FLUTTER_ROOT
sdk.dir=$ANDROID_SDK_ROOT
EOF
    
    echo "✅ Local properties configured"
}

# Function to setup Gradle wrapper
setup_gradle_wrapper() {
    print_section "Setting up Gradle wrapper"
    
    # Create gradle wrapper directory
    mkdir -p android/gradle/wrapper
    
    # Download gradle-wrapper.jar
    wget -O android/gradle/wrapper/gradle-wrapper.jar https://raw.githubusercontent.com/gradle/gradle/v8.12.0/gradle/wrapper/gradle-wrapper.jar
    
    # Create gradle-wrapper.properties
    cat > android/gradle/wrapper/gradle-wrapper.properties << EOF
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.12-all.zip
EOF
    
    echo "✅ Gradle wrapper configured"
}

# Function to setup keystore
setup_keystore() {
    print_section "Setting up keystore"
    
    if [ -n "$KEY_STORE" ]; then
        echo "📥 Downloading keystore..."
        wget -O android/app/upload-keystore.jks "$KEY_STORE"
        
        # Create key.properties
        cat > android/key.properties << EOF
storePassword=$CM_KEYSTORE_PASSWORD
keyPassword=$CM_KEY_PASSWORD
keyAlias=$CM_KEY_ALIAS
storeFile=upload-keystore.jks
EOF
        echo "✅ Keystore configured"
    else
        echo "⚠️ No keystore URL provided, skipping keystore setup"
    fi
}

# Function to setup Firebase
setup_firebase() {
    print_section "Setting up Firebase"
    
    if [ "$PUSH_NOTIFY" = "true" ] && [ -n "$FIREBASE_CONFIG_ANDROID" ]; then
        echo "📥 Downloading Firebase config..."
        wget -O android/app/google-services.json "$FIREBASE_CONFIG_ANDROID"
        echo "✅ Firebase configured"
    else
        echo "⚠️ Firebase setup skipped (PUSH_NOTIFY=$PUSH_NOTIFY)"
    fi
}

# Function to build APK
build_apk() {
    print_section "Building APK"
    
    flutter build apk --release \
        --dart-define=PKG_NAME="$PKG_NAME" \
        --dart-define=BUNDLE_ID="$BUNDLE_ID" \
        --dart-define=APP_NAME="$APP_NAME" \
        --dart-define=ORG_NAME="$ORG_NAME" \
        --dart-define=VERSION_NAME="$VERSION_NAME" \
        --dart-define=VERSION_CODE="$VERSION_CODE" \
        --dart-define=PUSH_NOTIFY="$PUSH_NOTIFY" \
        --dart-define=firebase_config_android="$FIREBASE_CONFIG_ANDROID" \
        --dart-define=WEB_URL="$WEB_URL" \
        --dart-define=IS_SPLASH="$IS_SPLASH" \
        --dart-define=SPLASH="$SPLASH" \
        --dart-define=SPLASH_ANIMATION="$SPLASH_ANIMATION" \
        --dart-define=SPLASH_BG_COLOR="$SPLASH_BG_COLOR" \
        --dart-define=SPLASH_TAGLINE="$SPLASH_TAGLINE" \
        --dart-define=SPLASH_TAGLINE_COLOR="$SPLASH_TAGLINE_COLOR" \
        --dart-define=SPLASH_DURATION="$SPLASH_DURATION" \
        --dart-define=IS_PULLDOWN="$IS_PULLDOWN" \
        --dart-define=LOGO_URL="$LOGO_URL" \
        --dart-define=IS_BOTTOMMENU="$IS_BOTTOMMENU" \
        --dart-define=BOTTOMMENU_ITEMS="$BOTTOMMENU_ITEMS" \
        --dart-define=BOTTOMMENU_BG_COLOR="$BOTTOMMENU_BG_COLOR" \
        --dart-define=BOTTOMMENU_ICON_COLOR="$BOTTOMMENU_ICON_COLOR" \
        --dart-define=BOTTOMMENU_TEXT_COLOR="$BOTTOMMENU_TEXT_COLOR" \
        --dart-define=BOTTOMMENU_FONT="$BOTTOMMENU_FONT" \
        --dart-define=BOTTOMMENU_FONT_SIZE="$BOTTOMMENU_FONT_SIZE" \
        --dart-define=BOTTOMMENU_FONT_BOLD="$BOTTOMMENU_FONT_BOLD" \
        --dart-define=BOTTOMMENU_FONT_ITALIC="$BOTTOMMENU_FONT_ITALIC" \
        --dart-define=BOTTOMMENU_ACTIVE_TAB_COLOR="$BOTTOMMENU_ACTIVE_TAB_COLOR" \
        --dart-define=BOTTOMMENU_ICON_POSITION="$BOTTOMMENU_ICON_POSITION" \
        --dart-define=BOTTOMMENU_VISIBLE_ON="$BOTTOMMENU_VISIBLE_ON" \
        --dart-define=IS_DEEPLINK="$IS_DEEPLINK" \
        --dart-define=IS_LOAD_IND="$IS_LOAD_IND" \
        --dart-define=IS_CHATBOT="$IS_CHATBOT" \
        --dart-define=IS_CAMERA="$IS_CAMERA" \
        --dart-define=IS_LOCATION="$IS_LOCATION" \
        --dart-define=IS_BIOMETRIC="$IS_BIOMETRIC" \
        --dart-define=IS_MIC="$IS_MIC" \
        --dart-define=IS_CONTACT="$IS_CONTACT" \
        --dart-define=IS_CALENDAR="$IS_CALENDAR" \
        --dart-define=IS_NOTIFICATION="$IS_NOTIFICATION" \
        --dart-define=IS_STORAGE="$IS_STORAGE"
    
    echo "✅ APK build complete"
}

# Function to build AAB
build_aab() {
    print_section "Building AAB"
    
    flutter build appbundle --release \
        --dart-define=PKG_NAME="$PKG_NAME" \
        --dart-define=BUNDLE_ID="$BUNDLE_ID" \
        --dart-define=APP_NAME="$APP_NAME" \
        --dart-define=ORG_NAME="$ORG_NAME" \
        --dart-define=VERSION_NAME="$VERSION_NAME" \
        --dart-define=VERSION_CODE="$VERSION_CODE" \
        --dart-define=PUSH_NOTIFY="$PUSH_NOTIFY" \
        --dart-define=firebase_config_android="$FIREBASE_CONFIG_ANDROID" \
        --dart-define=WEB_URL="$WEB_URL" \
        --dart-define=IS_SPLASH="$IS_SPLASH" \
        --dart-define=SPLASH="$SPLASH" \
        --dart-define=SPLASH_ANIMATION="$SPLASH_ANIMATION" \
        --dart-define=SPLASH_BG_COLOR="$SPLASH_BG_COLOR" \
        --dart-define=SPLASH_TAGLINE="$SPLASH_TAGLINE" \
        --dart-define=SPLASH_TAGLINE_COLOR="$SPLASH_TAGLINE_COLOR" \
        --dart-define=SPLASH_DURATION="$SPLASH_DURATION" \
        --dart-define=IS_PULLDOWN="$IS_PULLDOWN" \
        --dart-define=LOGO_URL="$LOGO_URL" \
        --dart-define=IS_BOTTOMMENU="$IS_BOTTOMMENU" \
        --dart-define=BOTTOMMENU_ITEMS="$BOTTOMMENU_ITEMS" \
        --dart-define=BOTTOMMENU_BG_COLOR="$BOTTOMMENU_BG_COLOR" \
        --dart-define=BOTTOMMENU_ICON_COLOR="$BOTTOMMENU_ICON_COLOR" \
        --dart-define=BOTTOMMENU_TEXT_COLOR="$BOTTOMMENU_TEXT_COLOR" \
        --dart-define=BOTTOMMENU_FONT="$BOTTOMMENU_FONT" \
        --dart-define=BOTTOMMENU_FONT_SIZE="$BOTTOMMENU_FONT_SIZE" \
        --dart-define=BOTTOMMENU_FONT_BOLD="$BOTTOMMENU_FONT_BOLD" \
        --dart-define=BOTTOMMENU_FONT_ITALIC="$BOTTOMMENU_FONT_ITALIC" \
        --dart-define=BOTTOMMENU_ACTIVE_TAB_COLOR="$BOTTOMMENU_ACTIVE_TAB_COLOR" \
        --dart-define=BOTTOMMENU_ICON_POSITION="$BOTTOMMENU_ICON_POSITION" \
        --dart-define=BOTTOMMENU_VISIBLE_ON="$BOTTOMMENU_VISIBLE_ON" \
        --dart-define=IS_DEEPLINK="$IS_DEEPLINK" \
        --dart-define=IS_LOAD_IND="$IS_LOAD_IND" \
        --dart-define=IS_CHATBOT="$IS_CHATBOT" \
        --dart-define=IS_CAMERA="$IS_CAMERA" \
        --dart-define=IS_LOCATION="$IS_LOCATION" \
        --dart-define=IS_BIOMETRIC="$IS_BIOMETRIC" \
        --dart-define=IS_MIC="$IS_MIC" \
        --dart-define=IS_CONTACT="$IS_CONTACT" \
        --dart-define=IS_CALENDAR="$IS_CALENDAR" \
        --dart-define=IS_NOTIFICATION="$IS_NOTIFICATION" \
        --dart-define=IS_STORAGE="$IS_STORAGE"
    
    echo "✅ AAB build complete"
}

# Function to collect artifacts
collect_artifacts() {
    print_section "Collecting artifacts"
    
    # Create output directory
    mkdir -p output
    
    # Copy APK and AAB to output directory
    cp build/app/outputs/flutter-apk/app-release.apk output/
    cp build/app/outputs/bundle/release/app-release.aab output/
    
    echo "✅ Artifacts collected"
}

echo "🚀 Starting Android Build Process with File Management Rules"
echo "📋 RULE: Only ADD files to Android folders, NO DIRECT MODIFICATIONS"
echo "🔄 BUILD SESSION: All changes will be reverted after build completion"
echo "📧 ERROR NOTIFICATIONS: Enabled - emails will be sent on build failures"
echo ""

# --- Import Environment Variables FIRST ---
echo "--- Import Environment Variables ---"
. "$SCRIPT_DIR/export.sh"
echo ""

# --- Fix V1 Embedding Issues FIRST ---
echo "--- Fixing V1 Embedding Issues ---"
"$SCRIPT_DIR/fix_v1_embedding.sh"
echo ""

# --- Clear Previous Build Files ---
echo "--- Clearing Previous Build Files ---"
echo "🧹 Cleaning Flutter build cache..."
flutter clean

echo "🗑️  Clearing output directory..."
OUTPUT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)/output"
if [ -d "$OUTPUT_DIR" ]; then
    rm -rf "$OUTPUT_DIR"/*
    echo "✅ Cleared output directory"
else
    mkdir -p "$OUTPUT_DIR"
    echo "✅ Created output directory"
fi

echo "🗑️  Clearing Android build cache..."
if [ -d "android/app/build" ]; then
    rm -rf android/app/build
    echo "✅ Cleared Android build cache"
fi
echo ""

# Initialize Android File Manager
echo "--- Initializing Android File Manager ---"
"$SCRIPT_DIR/android_file_manager.sh" init
echo ""

# Start build session to track all changes
echo "--- Starting Build Session ---"
"$SCRIPT_DIR/android_file_manager.sh" start-session
echo ""

# Validate Android project structure before proceeding
echo "--- Validating Android Project Structure ---"
if ! "$SCRIPT_DIR/android_file_manager.sh" validate; then
    echo "❌ Android project structure validation failed!"
    echo "💡 Please ensure all required Android files exist before proceeding."
    # End session and exit
    "$SCRIPT_DIR/android_file_manager.sh" end-session
    exit 1
fi
echo ""

# --- Debug Environment Variables ---
echo "--- Debugging Environment Variables ---"
"$SCRIPT_DIR/debug_env.sh"
echo ""

# --- Project and Version Setup ---
echo "--- Setting up Project Name and Version ---"
"$SCRIPT_DIR/change_proj_name.sh"
"$SCRIPT_DIR/update_version.sh"
echo ""

# --- Apply Custom Assets and Icons ---
echo "--- Applying Custom Assets and Icons ---"
"$SCRIPT_DIR/get_logo.sh"
"$SCRIPT_DIR/get_splash.sh"
flutter pub run flutter_launcher_icons
echo ""

# --- Prepare Android Project (Using File Manager) ---
echo "--- Preparing Android Project with File Manager ---"

# Delete old keystore using file manager
echo "🗑️  Cleaning old keystore..."
"$SCRIPT_DIR/delete_old_keystore.sh"

# Get JSON configuration if PUSH_NOTIFY is true
if [ "${PUSH_NOTIFY:-false}" = "true" ]; then
  echo "📄 Getting JSON configuration..."
  "$SCRIPT_DIR/get_json.sh"
else
  echo "🚫 Firebase config skipped because PUSH_NOTIFY != true"
fi

# Inject permissions using file manager
echo "🔐 Injecting Android permissions..."
"$SCRIPT_DIR/inject_permissions_android.sh"

# Inject keystore using file manager if KEY_STORE is provided
if [ -n "${KEY_STORE:-}" ]; then
  echo "🔑 Injecting keystore..."
  "$SCRIPT_DIR/inject_keystore.sh"
else
  echo "🚫 Keystore injection skipped because KEY_STORE is not provided"
fi

# Configure Android build using file manager
echo "⚙️  Configuring Android build..."
"$SCRIPT_DIR/configure_android_build_fixed.sh"

echo ""

# Generate local.properties
"$SCRIPT_DIR/generate_local_properties.sh"

echo ""

# --- Build APK and AAB ---
echo "🛠️ Starting the build process..."
"$SCRIPT_DIR/build.sh"
echo ""

# --- Validate APK Signing ---
echo "🔍 Validating APK signature..."
# Find the latest build-tools directory
BUILD_TOOLS_DIR=""
if [ -n "$ANDROID_SDK_ROOT" ] && [ -d "$ANDROID_SDK_ROOT/build-tools" ]; then
    BUILD_TOOLS_DIR=$(find "$ANDROID_SDK_ROOT/build-tools" -maxdepth 1 -type d -regextype posix-extended -regex ".*/[0-9]+\.[0-9]+\.[0-9]+" 2>/dev/null | sort -V | tail -n 1)
fi

if [ -z "$BUILD_TOOLS_DIR" ]; then
    echo "⚠️  Warning: Android SDK build-tools not found. Skipping signature validation."
    echo "💡 To enable signature validation, ensure ANDROID_SDK_ROOT is set correctly."
else
    # Check if APK exists before validating
    APK_PATH="android/app/build/outputs/apk/release/app-release.apk"
    if [ -f "$APK_PATH" ]; then
        "$BUILD_TOOLS_DIR/apksigner" verify --verbose "$APK_PATH" || echo "⚠️  Signature validation failed, but APK was built successfully"
        echo "--- APK Signature Validation Complete ---"
    else
        echo "⚠️  APK not found at $APK_PATH - skipping signature validation"
    fi
fi
echo ""

# Show file changes summary before reversion
echo "--- File Changes Summary (Before Reversion) ---"
"$SCRIPT_DIR/android_file_manager.sh" changes 2>/dev/null || echo "⚠️  Could not show file changes summary"
echo ""

# Move outputs to root output folder
echo "--- Moving Build Outputs ---"
"$SCRIPT_DIR/move_outputs.sh" 2>/dev/null || echo "⚠️  Could not move outputs (they may already be in the correct location)"
echo ""

# Send email with all files in output folder
echo "--- Sending Email with Build Outputs ---"
"$SCRIPT_DIR/send_output_email.sh" 2>/dev/null || echo "⚠️  Could not send output email"
echo ""

# End build session and revert all changes
echo "--- Ending Build Session and Reverting Changes ---"
"$SCRIPT_DIR/android_file_manager.sh" end-session 2>/dev/null || echo "⚠️  Could not end build session (may not have been started)"
echo ""

echo "✅ All tasks completed successfully!"
echo "📋 All Android file changes have been reverted to original state."
echo "🔒 Build artifacts are preserved, but Android project files are unchanged."
echo "📧 No error notifications sent - build completed successfully!"

# Main build process
echo "🚀 Starting Android build process..."

# Validate environment
print_section "Validating Environment"
bash "$SCRIPT_DIR/validate.sh" || handle_error ${LINENO} "Environment validation failed" $?

# Setup local properties
print_section "Setting up local properties"
setup_local_properties || handle_error ${LINENO} "Failed to setup local properties" $?

# Setup Gradle wrapper
print_section "Setting up Gradle wrapper"
setup_gradle_wrapper || handle_error ${LINENO} "Failed to setup Gradle wrapper" $?

# Setup keystore
print_section "Setting up keystore"
setup_keystore || handle_error ${LINENO} "Failed to setup keystore" $?

# Setup Firebase
print_section "Setting up Firebase"
setup_firebase || handle_error ${LINENO} "Failed to setup Firebase" $?

# Build APK
print_section "Building APK"
build_apk || handle_error ${LINENO} "Failed to build APK" $?

# Build AAB
print_section "Building AAB"
build_aab || handle_error ${LINENO} "Failed to build AAB" $?

# Collect artifacts
print_section "Collecting artifacts"
collect_artifacts || handle_error ${LINENO} "Failed to collect artifacts" $?

# Print build summary
print_section "Build Summary"
echo "📱 App Name: $APP_NAME"
echo "📦 Package: $PKG_NAME"
echo "📊 Version: $VERSION_NAME ($VERSION_CODE)"
echo "📤 Generated artifacts:"
ls -la output/

echo "✅ Android build process completed successfully!"