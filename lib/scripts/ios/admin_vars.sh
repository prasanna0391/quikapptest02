#!/bin/bash

# Ensure CM_BUILD_DIR is set
if [ -z "$CM_BUILD_DIR" ]; then
    CM_BUILD_DIR="$PWD"
fi

# Build Configuration
export BUILD_MODE="app-store"
export FLUTTER_VERSION="3.19.3"
export XCODE_VERSION="15.0"
export SWIFT_VERSION="5.0"

# iOS Configuration
export IOS_DEPLOYMENT_TARGET="12.0"
export IOS_BUILD_SDK="17.0"
export IOS_SIMULATOR_SDK="17.0"
export IOS_ARCHIVE_PATH="build/ios/archive/Runner.xcarchive"
export IOS_EXPORT_PATH="build/ios/ipa"

# Path Configuration
export PROJECT_ROOT="${CM_BUILD_DIR}"
export IOS_ROOT="${PROJECT_ROOT}/ios"
export ASSETS_DIR="${PROJECT_ROOT}/assets"
export OUTPUT_DIR="${PROJECT_ROOT}/build/outputs"
export TEMP_DIR="${PROJECT_ROOT}/build/temp"

# iOS Paths
export IOS_PROJECT_PATH="${IOS_ROOT}/Runner.xcodeproj"
export IOS_WORKSPACE_PATH="${IOS_ROOT}/Runner.xcworkspace"
export IOS_INFO_PLIST_PATH="${IOS_ROOT}/Runner/Info.plist"
export IOS_ENTITLEMENTS_PATH="${IOS_ROOT}/Runner/Runner.entitlements"
export IOS_PROVISIONING_PROFILE_PATH="${IOS_ROOT}/Runner/embedded.mobileprovision"
export IOS_CERTIFICATE_PATH="${IOS_ROOT}/Runner/certificate.p12"
export IOS_APP_ICON_PATH="${IOS_ROOT}/Runner/Assets.xcassets/AppIcon.appiconset"
export IOS_SPLASH_PATH="${IOS_ROOT}/Runner/Assets.xcassets/Splash.imageset"

# Asset Paths
export APP_ICON_PATH="${ASSETS_DIR}/app_icon.png"
export SPLASH_IMAGE_PATH="${ASSETS_DIR}/splash.png"
export SPLASH_BG_PATH="${ASSETS_DIR}/splash_bg.png"
export PUBSPEC_BACKUP_PATH="${PROJECT_ROOT}/pubspec.yaml.bak"

# Build Output Paths
export IPA_OUTPUT_PATH="${OUTPUT_DIR}/Runner.ipa"
export APP_OUTPUT_PATH="${OUTPUT_DIR}/Runner.app"

# Download Configuration
export DOWNLOAD_MAX_RETRIES=3
export DOWNLOAD_RETRY_DELAY=5

# Notification Configuration
export NOTIFICATION_EMAIL_FROM="builds@example.com"
export NOTIFICATION_EMAIL_TO="team@example.com"
export NOTIFICATION_EMAIL_SUBJECT="iOS Build Notification"

# Keystore Configuration
export IOS_CERTIFICATE_BASE64=""  # Set this if you have a base64-encoded certificate
export IOS_PROVISIONING_PROFILE_BASE64=""  # Set this if you have a base64-encoded provisioning profile
export IOS_CERTIFICATE_PASSWORD=""  # Set this if your certificate is password protected

# Firebase Configuration
export FIREBASE_CONFIG_URL=""  # Set this if you have a Firebase config URL
export FIREBASE_ENABLED=false  # Set to true if Firebase is enabled 