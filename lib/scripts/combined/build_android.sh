#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Function to handle errors
handle_error() {
    local error_msg="$1"
    echo "❌ Error: $error_msg"
    bash "$(dirname "$0")/send_error_email.sh" "Android Build Failed" "$error_msg"
    exit 1
}

# Function to setup Android keystore
setup_keystore() {
    echo "🔐 Setting up Android keystore..."
    
    if [ -n "$KEY_STORE" ]; then
        # Download keystore
        wget -O android/app/keystore.jks "$KEY_STORE" || handle_error "Failed to download keystore"
        
        # Create key.properties
        cat > android/key.properties << EOF
storePassword=$CM_KEYSTORE_PASSWORD
keyPassword=$CM_KEY_PASSWORD
keyAlias=$CM_KEY_ALIAS
storeFile=keystore.jks
EOF
    fi
    
    echo "✅ Keystore setup complete"
}

# Function to setup Firebase
setup_firebase() {
    echo "🔥 Setting up Firebase..."
    
    if [ "$PUSH_NOTIFY" = "true" ] && [ -n "$FIREBASE_CONFIG_ANDROID" ]; then
        # Download google-services.json
        wget -O android/app/google-services.json "$FIREBASE_CONFIG_ANDROID" || handle_error "Failed to download Firebase config"
    fi
    
    echo "✅ Firebase setup complete"
}

# Function to setup local.properties
setup_local_properties() {
    echo "📝 Setting up local.properties..."
    
    # Create local.properties
    cat > android/local.properties << EOF
sdk.dir=$ANDROID_HOME
flutter.sdk=$(dirname $(dirname $(which flutter)))
EOF
    
    echo "✅ local.properties setup complete"
}

# Function to build APK
build_apk() {
    echo "🏗️ Building Android APK..."
    
    flutter build apk --release \
        --dart-define=PKG_NAME="$PKG_NAME" \
        --dart-define=APP_NAME="$APP_NAME" \
        --dart-define=VERSION_NAME="$VERSION_NAME" \
        --dart-define=VERSION_CODE="$VERSION_CODE" \
        --dart-define=PUSH_NOTIFY="$PUSH_NOTIFY" \
        --dart-define=WEB_URL="$WEB_URL" || handle_error "Failed to build APK"
    
    echo "✅ APK build complete"
}

# Function to build AAB
build_aab() {
    echo "🏗️ Building Android App Bundle..."
    
    flutter build appbundle --release \
        --dart-define=PKG_NAME="$PKG_NAME" \
        --dart-define=APP_NAME="$APP_NAME" \
        --dart-define=VERSION_NAME="$VERSION_NAME" \
        --dart-define=VERSION_CODE="$VERSION_CODE" \
        --dart-define=PUSH_NOTIFY="$PUSH_NOTIFY" \
        --dart-define=WEB_URL="$WEB_URL" || handle_error "Failed to build AAB"
    
    echo "✅ AAB build complete"
}

# Function to collect Android artifacts
collect_artifacts() {
    echo "📦 Collecting Android artifacts..."
    
    # Create output directory
    mkdir -p output
    
    # Copy APK
    if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
        cp build/app/outputs/flutter-apk/app-release.apk output/
        echo "✅ APK copied to output/"
    fi
    
    # Copy AAB
    if [ -f "build/app/outputs/bundle/release/app-release.aab" ]; then
        cp build/app/outputs/bundle/release/app-release.aab output/
        echo "✅ AAB copied to output/"
    fi
    
    echo "✅ Android artifacts collected"
}

# Main Android build process
echo "🚀 Starting Android build process..."

setup_keystore
setup_firebase
setup_local_properties
build_apk
build_aab
collect_artifacts

echo "✅ Android build process completed successfully" 