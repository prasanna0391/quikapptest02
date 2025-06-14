#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

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

# Function to clean previous builds
clean_builds() {
    print_section "Cleaning previous builds"
    flutter clean
    rm -rf output/
    echo "✅ Clean complete"
}

# Function to setup Flutter SDK path
setup_flutter_sdk() {
    print_section "Setting up Flutter SDK path"
    
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
    
    echo "✅ Flutter SDK path configured"
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

# Main build process
echo "🚀 Starting build process..."

# Load environment variables
print_section "Loading environment variables"
source "$SCRIPT_DIR/export.sh"
echo "✅ Environment variables loaded"

# Validate environment
print_section "Validating environment"
bash "$SCRIPT_DIR/validate.sh"
echo "✅ Environment validated"

# Clean previous builds
clean_builds

# Setup Flutter SDK and Gradle
setup_flutter_sdk
setup_gradle_wrapper

# Configure app
print_section "Configuring app"
bash "$SCRIPT_DIR/configure_app.sh"
echo "✅ App configured"

# Build Android
print_section "Building Android"
bash "$SCRIPT_DIR/build_android.sh"
echo "✅ Android build complete"

# Build iOS
print_section "Building iOS"
bash "$SCRIPT_DIR/build_ios.sh"
echo "✅ iOS build complete"

# Print build summary
print_section "Build Summary"
echo "📱 App Name: $APP_NAME"
echo "📦 Package: $PKG_NAME"
echo "🆔 Bundle ID: $BUNDLE_ID"
echo "📊 Version: $VERSION_NAME ($VERSION_CODE)"
echo "📤 Generated artifacts:"
ls -la output/

echo "✅ Build process completed successfully!" 