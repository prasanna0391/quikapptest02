#!/bin/bash
set -e

# Source download functions
source lib/scripts/combined/download.sh

# Error handling function
handle_error() {
    local line_no=$1
    local error_code=$2
    local command=$3
    echo "❌ Error occurred in $0 at line $line_no (exit code: $error_code)"
    echo "Failed command: $command"
    bash lib/scripts/combined/send_error_email.sh "Build Failed" "iOS build failed at line $line_no: $command"
    exit 1
}

# Set error handler
trap 'handle_error ${LINENO} $? "$BASH_COMMAND"' ERR

# Print section header
print_section() {
    echo "=== $1 ==="
}

# Main build process
print_section "Starting iOS Build Process"

# Setup environment
print_section "Setting up environment"
find lib/scripts -type f -name "*.sh" -exec chmod +x {} \;
mkdir -p output
source lib/scripts/combined/export.sh

# Validate environment
print_section "Validating environment"
bash lib/scripts/combined/validate.sh

# Configure app details
print_section "Configuring app details"
# Update app name in iOS
/usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName $APP_NAME" ios/Runner/Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleName $APP_NAME" ios/Runner/Info.plist

# Update bundle identifier in iOS
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $BUNDLE_ID" ios/Runner/Info.plist

# Download and setup app icon
download_app_icon

# Download and setup splash screen
download_splash_assets

# Setup certificates and provisioning
print_section "Setting up certificates and provisioning"
setup_certificates() {
    echo "Setting up certificates and provisioning..."
    if download_certificates; then
        # Create keychain
        security create-keychain -p "$CERT_PASSWORD" build.keychain
        security default-keychain -s build.keychain
        security unlock-keychain -p "$CERT_PASSWORD" build.keychain
        
        # Import certificates
        security import cert.p12 -k build.keychain -P "$CERT_PASSWORD" -A
        security import key.p12 -k build.keychain -P "$CERT_PASSWORD" -A
        
        # Install provisioning profile
        mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
        cp profile.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/
        
        # Clean up
        rm -f cert.p12 key.p12 profile.mobileprovision
        return 0
    else
        return 1
    fi
}
setup_certificates

# Setup Firebase
print_section "Setting up Firebase"
download_firebase_config "iOS" "$FIREBASE_CONFIG_IOS" "ios/Runner/GoogleService-Info.plist"

# Build iOS app
print_section "Building iOS app"
build_ios() {
    echo "Building iOS app..."
    flutter build ios --release --no-codesign
}
build_ios

# Archive and export IPA
print_section "Archiving and exporting IPA"
archive_and_export() {
    echo "Archiving and exporting IPA..."
    xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Release -archivePath build/Runner.xcarchive archive
    xcodebuild -exportArchive -archivePath build/Runner.xcarchive -exportOptionsPlist ios/exportOptions.plist -exportPath build/ios/ipa
}
archive_and_export

# Collect artifacts
print_section "Collecting artifacts"
collect_artifacts() {
    echo "Collecting build artifacts..."
    mkdir -p output
    cp build/ios/ipa/Runner.ipa output/
    cp -r build/Runner.xcarchive output/
}
collect_artifacts

# Revert changes
print_section "Reverting changes"
revert_changes() {
    echo "Reverting project changes..."
    git checkout ios/Runner/Info.plist
    rm -f assets/icon.png
    rm -f assets/splash.png
    rm -f assets/splash_bg.png
    rm -f pubspec.yaml.bak
    rm -rf ios/Runner/Assets.xcassets/AppIcon.appiconset/*
    rm -rf ios/Runner/Assets.xcassets/Splash.imageset/*
}
revert_changes

# Send success notification
print_section "Sending build notification"
bash lib/scripts/combined/send_error_email.sh "Build Complete" "iOS build process completed successfully"

print_section "iOS Build Process Completed" 