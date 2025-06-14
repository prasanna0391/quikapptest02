#!/bin/bash

# Common Build Configuration
export BUILD_MODE="release"
export FLUTTER_VERSION="stable"
export XCODE_VERSION="14.2"
export COCOAPODS_VERSION="1.12.1"

# Common Path Configuration
export PROJECT_ROOT="$CM_BUILD_DIR"
export IOS_ROOT="$PROJECT_ROOT/ios"
export ASSETS_DIR="$PROJECT_ROOT/assets"
export OUTPUT_DIR="$CM_BUILD_DIR/build"
export TEMP_DIR="$CM_BUILD_DIR/temp"

# Common Download Configuration
export DOWNLOAD_MAX_RETRIES=3
export DOWNLOAD_RETRY_DELAY=5

# Balance Variables Configuration
# These variables will be moved to database in future
# For now, they are hardcoded for testing purposes

# iOS Configuration
export IOS_DEPLOYMENT_TARGET="12.0"

# iOS Paths
export IOS_INFO_PLIST_PATH="$IOS_ROOT/Runner/Info.plist"
export IOS_PROJECT_PATH="$IOS_ROOT/Runner.xcodeproj"
export IOS_WORKSPACE_PATH="$IOS_ROOT/Runner.xcworkspace"
export IOS_FIREBASE_CONFIG_PATH="$IOS_ROOT/Runner/GoogleService-Info.plist"
export IOS_CERTIFICATES_DIR="$IOS_ROOT/certificates"
export IOS_PROVISIONING_DIR="$IOS_ROOT/provisioning"

# Asset Paths
export APP_ICON_PATH="$ASSETS_DIR/icon.png"
export SPLASH_IMAGE_PATH="$ASSETS_DIR/splash.png"
export SPLASH_BG_PATH="$ASSETS_DIR/splash_bg.png"
export PUBSPEC_BACKUP_PATH="$PROJECT_ROOT/pubspec.yaml.bak"

# Build Output Paths
export IPA_OUTPUT_PATH="$IOS_ROOT/build/ios/ipa/Runner.ipa"

# Notification Configuration
export NOTIFICATION_EMAIL_FROM="build@example.com"
export NOTIFICATION_EMAIL_TO="$EMAIL_ID"
export NOTIFICATION_EMAIL_SUBJECT="Build Status" 