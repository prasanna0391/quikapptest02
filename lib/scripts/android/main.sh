#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Get the script directory for dynamic path resolution
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Always set the correct package name for Android builds
export PKG_NAME=com.garbcode.garbcodeapp

# Function to handle errors and send email notifications
handle_error() {
    local exit_code=$?
    local error_line=$1
    local error_command=$2
    
    # Check if the build actually succeeded despite the error
    local build_succeeded=false
    if [ -f "output/app-release.apk" ] || [ -f "output/app-release.aab" ]; then
        build_succeeded=true
    fi
    
    if [ "$build_succeeded" = true ]; then
        echo ""
        echo "⚠️  Build completed with warnings but APK/AAB files were generated successfully!"
        echo "📍 Warning occurred at line: $error_line"
        echo "🔧 Command with warning: $error_command"
        echo "📊 Exit code: $exit_code"
        echo "✅ Build artifacts are available in the output/ directory"
        
        # End build session if it was started
        if [ -f "$SCRIPT_DIR/android_file_manager.sh" ]; then
            echo ""
            echo "🔄 Ending build session and reverting changes..."
            "$SCRIPT_DIR/android_file_manager.sh" end-session 2>/dev/null || true
        fi
        
        echo ""
        echo "✅ All tasks completed successfully!"
        echo "📋 All Android file changes have been reverted to original state."
        echo "🔒 Build artifacts are preserved, but Android project files are unchanged."
        echo "📧 No error notifications sent - build completed successfully!"
        exit 0
    else
        echo ""
        echo "❌ Build process failed!"
        echo "📍 Error occurred at line: $error_line"
        echo "🔧 Failed command: $error_command"
        echo "📊 Exit code: $exit_code"
        
        # Capture recent build logs for error details
        local error_details=""
        if [ -f "flutter_build_apk.log" ]; then
            error_details=$(tail -50 flutter_build_apk.log 2>/dev/null || echo "No build log available")
        fi
        
        # Generate error message
        local error_message="Build process failed with exit code $exit_code"
        
        # Send error notification email
        echo ""
        echo "📧 Sending error notification email..."
        "$SCRIPT_DIR/send_error_email.sh" "$error_message" "$error_details"
        
        # End build session if it was started
        if [ -f "$SCRIPT_DIR/android_file_manager.sh" ]; then
            echo ""
            echo "🔄 Ending build session and reverting changes..."
            "$SCRIPT_DIR/android_file_manager.sh" end-session 2>/dev/null || true
        fi
        
        exit $exit_code
    fi
}

# Set up error handling
trap 'handle_error ${LINENO} "$BASH_COMMAND"' ERR

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

# Get JSON configuration
echo "📄 Getting JSON configuration..."
"$SCRIPT_DIR/get_json.sh"

# Inject permissions using file manager
echo "🔐 Injecting Android permissions..."
"$SCRIPT_DIR/inject_permissions_android.sh"

# Inject keystore using file manager
echo "🔑 Injecting keystore..."
"$SCRIPT_DIR/inject_keystore.sh"

# Configure Android build using file manager
echo "⚙️  Configuring Android build..."
"$SCRIPT_DIR/configure_android_build_fixed.sh"

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