#!/bin/bash

# Ensure CM_BUILD_DIR is set
if [ -z "$CM_BUILD_DIR" ]; then
    CM_BUILD_DIR="$PWD"
fi

# Build Configuration
export BUILD_MODE="app-store"
export FLUTTER_VERSION="3.19.3"
export XCODE_VERSION="15.2"
export COCOAPODS_VERSION="1.14.3"

# iOS Configuration
export IOS_DEPLOYMENT_TARGET="12.0"

# Path Configuration
export PROJECT_ROOT="${CM_BUILD_DIR}"
export IOS_ROOT="${PROJECT_ROOT}/ios"
export ASSETS_DIR="${PROJECT_ROOT}/assets"
export OUTPUT_DIR="${PROJECT_ROOT}/build/outputs"
export TEMP_DIR="${PROJECT_ROOT}/build/temp"

# iOS Paths
export IOS_INFO_PLIST_PATH="${IOS_ROOT}/Runner/Info.plist"
export IOS_PROJECT_PATH="${IOS_ROOT}/Runner.xcodeproj"
export IOS_WORKSPACE_PATH="${IOS_ROOT}/Runner.xcworkspace"
export IOS_FIREBASE_CONFIG_PATH="${IOS_ROOT}/Runner/GoogleService-Info.plist"
export IOS_CERTIFICATES_DIR="${IOS_ROOT}/certificates"
export IOS_PROVISIONING_DIR="${IOS_ROOT}/provisioning"

# Asset Paths
export APP_ICON_PATH="${ASSETS_DIR}/app_icon.png"
export SPLASH_IMAGE_PATH="${ASSETS_DIR}/splash.png"
export SPLASH_BG_PATH="${ASSETS_DIR}/splash_bg.png"
export PUBSPEC_BACKUP_PATH="${PROJECT_ROOT}/pubspec.yaml.bak"

# Build Output Paths
export IPA_OUTPUT_PATH="${OUTPUT_DIR}/Runner.ipa"

# Download Configuration
export DOWNLOAD_MAX_RETRIES=3
export DOWNLOAD_RETRY_DELAY=5

# Notification Configuration
export NOTIFICATION_EMAIL_FROM="builds@example.com"
export NOTIFICATION_EMAIL_TO="team@example.com"
export NOTIFICATION_EMAIL_SUBJECT="iOS Build Notification" 