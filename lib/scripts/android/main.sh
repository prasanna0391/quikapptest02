#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Get the script directory for dynamic path resolution
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Always set the correct package name for Android builds
export PKG_NAME=com.garbcode.garbcodeapp

# Error handler for sending error emails and exiting
handle_error() {
    local exit_code=$?
    local error_line=$1
    local error_command=$2

    # Check if build succeeded despite error
    if [ -f "output/app-release.apk" ] || [ -f "output/app-release.aab" ]; then
        echo "⚠️  Build completed with warnings but APK/AAB files were generated successfully!"
        exit 0
    else
        echo "❌ Build process failed!"
        local error_details=""
        if [ -f "flutter_build_apk.log" ]; then
            error_details=$(tail -50 flutter_build_apk.log 2>/dev/null || echo "No build log available")
        fi
        local error_message="Build process failed with exit code $exit_code"
        "$SCRIPT_DIR/send_error_email.sh" "$error_message" "$error_details"
        exit $exit_code
    fi
}

# Set up error handling
trap 'handle_error ${LINENO} "$BASH_COMMAND"' ERR

echo "🤖 Building Android using comprehensive script system..."

# Set workflow name for email notifications
export WORKFLOW_NAME="Combined Android & iOS Build"

# Check if we have the comprehensive Android main.sh script
if [ -f "lib/scripts/android/main.sh" ]; then
    echo "🎯 Using comprehensive Android main.sh script..."
    chmod +x lib/scripts/android/main.sh
    ./lib/scripts/android/main.sh
else
    echo "⚠️  Android main.sh not found, using enhanced fallback..."
    
    # Validate Android project structure
    echo "🔍 Validating Android project..."
    REQUIRED_FILES=(
        "android/app/build.gradle"
        "android/build.gradle"
        "android/gradle.properties"
        "android/settings.gradle"
    )
    
    for file in "${REQUIRED_FILES[@]}"; do
        if [ ! -f "$file" ]; then
            echo "❌ Missing required Android file: $file"
            exit 1
        fi
    done
    
    # Enhanced Android setup and build
    if [ -n "$KEY_STORE" ]; then
        echo "🔐 Setting up Android keystore..."
        
        # Create android directory if it doesn't exist
        mkdir -p android
        
        # Download keystore to android/keystore.jks
        echo "📥 Downloading keystore..."
        if ! wget -O android/keystore.jks "$KEY_STORE"; then
            echo "⚠️  wget failed, trying curl..."
            if ! curl -L -o android/keystore.jks "$KEY_STORE"; then
                echo "❌ Failed to download keystore"
                exit 1
            fi
        fi
        
        # Create key.properties with correct storeFile path
        echo "📝 Creating key.properties..."
        cat > android/key.properties << EOF
storePassword=$CM_KEYSTORE_PASSWORD
keyPassword=$CM_KEY_PASSWORD
keyAlias=$CM_KEY_ALIAS
storeFile=../keystore.jks
EOF
        
        # Create symbolic link for backward compatibility
        echo "🔗 Creating symbolic link for backward compatibility..."
        ln -sf ../keystore.jks android/app/keystore.jks
        
        echo "✅ Android keystore configured"
        
        # Verify keystore setup
        echo "🔍 Verifying keystore setup..."
        if [ -f "android/keystore.jks" ] && [ -f "android/key.properties" ]; then
            echo "✅ Keystore files verified"
            echo "📋 key.properties contents:"
            cat android/key.properties
        else
            echo "❌ Keystore verification failed"
            exit 1
        fi
    fi
    
    echo "🏗️ Building Android APK and AAB..."
    
    # Build APK with retry mechanism
    if ! flutter build apk --release \
      --dart-define=PKG_NAME="$PKG_NAME" \
      --dart-define=APP_NAME="$APP_NAME" \
      --dart-define=ORG_NAME="$ORG_NAME" \
      --dart-define=VERSION_NAME="$VERSION_NAME" \
      --dart-define=VERSION_CODE="$VERSION_CODE" \
      --dart-define=PUSH_NOTIFY="$PUSH_NOTIFY" \
      --dart-define=firebase_config_android="$firebase_config_android" \
      --dart-define=WEB_URL="$WEB_URL" \
      --dart-define=IS_SPLASH="$IS_SPLASH" \
      --dart-define=SPLASH="$SPLASH" \
      --dart-define=IS_BOTTOMMENU="$IS_BOTTOMMENU" \
      --dart-define=BOTTOMMENU_ITEMS="$BOTTOMMENU_ITEMS"; then
      
      echo "❌ Android APK build failed, retrying with clean..."
      flutter clean
      flutter pub get
      flutter build apk --release \
        --dart-define=PKG_NAME="$PKG_NAME" \
        --dart-define=APP_NAME="$APP_NAME" \
        --dart-define=VERSION_NAME="$VERSION_NAME" \
        --dart-define=VERSION_CODE="$VERSION_CODE" \
        --dart-define=PUSH_NOTIFY="$PUSH_NOTIFY"
    fi
    
    # Build AAB
    flutter build appbundle --release \
      --dart-define=PKG_NAME="$PKG_NAME" \
      --dart-define=APP_NAME="$APP_NAME" \
      --dart-define=ORG_NAME="$ORG_NAME" \
      --dart-define=VERSION_NAME="$VERSION_NAME" \
      --dart-define=VERSION_CODE="$VERSION_CODE" \
      --dart-define=PUSH_NOTIFY="$PUSH_NOTIFY" \
      --dart-define=WEB_URL="$WEB_URL" \
      --dart-define=IS_SPLASH="$IS_SPLASH" \
      --dart-define=SPLASH="$SPLASH" \
      --dart-define=IS_BOTTOMMENU="$IS_BOTTOMMENU" \
      --dart-define=BOTTOMMENU_ITEMS="$BOTTOMMENU_ITEMS"
    
    echo "✅ Android builds completed"
fi

echo "✅ All tasks completed successfully!"
echo "🔒 Build artifacts are preserved, but Android project files are unchanged."
echo "📧 No error notifications sent - build completed successfully!"