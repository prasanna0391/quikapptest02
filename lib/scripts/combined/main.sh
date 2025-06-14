#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source download functions
source "$SCRIPT_DIR/download.sh"

# Function to handle errors
handle_error() {
    local line_no=$1
    local error_code=$2
    local command=$3
    echo "❌ Error occurred in $0 at line $line_no (exit code: $error_code)"
    echo "Failed command: $command"
    bash "$SCRIPT_DIR/send_error_email.sh" "Build Failed" "Combined build failed at line $line_no: $command"
    exit 1
}

# Set error handler
trap 'handle_error ${LINENO} $? "$BASH_COMMAND"' ERR

# Function to print section headers
print_section() {
    echo "=== $1 ==="
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
print_section "Starting Combined Build Process"

# Setup environment
print_section "Setting up environment"
find "$SCRIPT_DIR" -type f -name "*.sh" -exec chmod +x {} \;
mkdir -p output
source "$SCRIPT_DIR/export.sh"

# Validate environment
print_section "Validating environment"
bash "$SCRIPT_DIR/validate.sh"

# Configure app details
print_section "Configuring app details"

# Update Android configuration
echo "Updating Android configuration..."
sed -i '' "s/android:label=\"[^\"]*\"/android:label=\"$APP_NAME\"/" android/app/src/main/AndroidManifest.xml
sed -i '' "s/applicationId \"[^\"]*\"/applicationId \"$PKG_NAME\"/" android/app/build.gradle

# Update iOS configuration
echo "Updating iOS configuration..."
/usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName $APP_NAME" ios/Runner/Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleName $APP_NAME" ios/Runner/Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $BUNDLE_ID" ios/Runner/Info.plist

# Download and setup app icon
download_app_icon

# Download and setup splash screen
download_splash_assets

# Build Android
print_section "Building Android"
echo "Running Android build script..."
bash "$SCRIPT_DIR/android/main.sh"

# Build iOS
print_section "Building iOS"
echo "Running iOS build script..."
bash "$SCRIPT_DIR/ios/main.sh"

# Revert changes
print_section "Reverting changes"
revert_changes() {
    echo "Reverting project changes..."
    # Revert Android files
    git checkout android/app/src/main/AndroidManifest.xml
    git checkout android/app/build.gradle

    # Revert iOS files
    git checkout ios/Runner/Info.plist

    # Remove downloaded assets
    rm -f assets/icon.png
    rm -f assets/splash.png
    rm -f assets/splash_bg.png

    # Remove generated files
    rm -f pubspec.yaml.bak
    rm -rf android/app/src/main/res/mipmap-*
    rm -rf android/app/src/main/res/drawable-*
    rm -rf ios/Runner/Assets.xcassets/AppIcon.appiconset/*
    rm -rf ios/Runner/Assets.xcassets/Splash.imageset/*
}
revert_changes

# Send success notification
print_section "Sending build notification"
bash "$SCRIPT_DIR/send_error_email.sh" "Build Complete" "Combined build process completed successfully"

print_section "Combined Build Process Completed" 