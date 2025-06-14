#!/bin/bash

# Common Build Configuration
export BUILD_MODE="release"
export FLUTTER_VERSION="stable"
export GRADLE_VERSION="7.5"
export JAVA_VERSION="11"
export XCODE_VERSION="14.2"
export COCOAPODS_VERSION="1.12.1"

# Common Path Configuration
export PROJECT_ROOT="$CM_BUILD_DIR"
export ANDROID_ROOT="$PROJECT_ROOT/android"
export IOS_ROOT="$PROJECT_ROOT/ios"
export ASSETS_DIR="$PROJECT_ROOT/assets"
export OUTPUT_DIR="$CM_BUILD_DIR/build"
export TEMP_DIR="$CM_BUILD_DIR/temp"

# Common Download Configuration
export DOWNLOAD_MAX_RETRIES=3
export DOWNLOAD_RETRY_DELAY=5

# Build Configuration
export BUILD_MODE="release"
export FLUTTER_VERSION="stable"
export GRADLE_VERSION="7.5"
export JAVA_VERSION="11"
export XCODE_VERSION="14.2"
export COCOAPODS_VERSION="1.12.1"

# Android Configuration
export ANDROID_COMPILE_SDK="33"
export ANDROID_MIN_SDK="21"
export ANDROID_TARGET_SDK="33"
export ANDROID_BUILD_TOOLS="33.0.0"
export ANDROID_NDK_VERSION="25.1.8937393"
export ANDROID_CMDLINE_TOOLS="9477386"

# iOS Configuration
export IOS_DEPLOYMENT_TARGET="12.0"

# Path Configuration
export PROJECT_ROOT="$CM_BUILD_DIR"
export ANDROID_ROOT="$PROJECT_ROOT/android"
export IOS_ROOT="$PROJECT_ROOT/ios"
export ASSETS_DIR="$PROJECT_ROOT/assets"
export OUTPUT_DIR="$CM_BUILD_DIR/build"
export TEMP_DIR="$CM_BUILD_DIR/temp"

# Android Paths
export ANDROID_MANIFEST_PATH="$ANDROID_ROOT/app/src/main/AndroidManifest.xml"
export ANDROID_BUILD_GRADLE_PATH="$ANDROID_ROOT/app/build.gradle"
export ANDROID_LOCAL_PROPERTIES_PATH="$ANDROID_ROOT/local.properties"
export ANDROID_KEY_PROPERTIES_PATH="$ANDROID_ROOT/key.properties"
export ANDROID_KEYSTORE_PATH="$ANDROID_ROOT/app/keystore.jks"
export ANDROID_FIREBASE_CONFIG_PATH="$ANDROID_ROOT/app/google-services.json"
export ANDROID_MIPMAP_DIR="$ANDROID_ROOT/app/src/main/res/mipmap-xxxhdpi"
export ANDROID_DRAWABLE_DIR="$ANDROID_ROOT/app/src/main/res/drawable"

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
export APK_OUTPUT_PATH="$ANDROID_ROOT/app/build/outputs/flutter-apk/app-release.apk"
export AAB_OUTPUT_PATH="$ANDROID_ROOT/app/build/outputs/bundle/release/app-release.aab"
export IPA_OUTPUT_PATH="$IOS_ROOT/build/ios/ipa/Runner.ipa"

# Gradle Configuration
export GRADLE_WRAPPER_DIR="$ANDROID_ROOT/gradle/wrapper"
export GRADLE_WRAPPER_JAR_PATH="$GRADLE_WRAPPER_DIR/gradle-wrapper.jar"
export GRADLE_WRAPPER_PROPERTIES_PATH="$GRADLE_WRAPPER_DIR/gradle-wrapper.properties"
export GRADLE_WRAPPER_URL="https://raw.githubusercontent.com/gradle/gradle/v7.5.0/gradle/wrapper/gradle-wrapper.jar"
export GRADLE_DISTRIBUTION_URL="https\://services.gradle.org/distributions/gradle-7.5-all.zip"

# Notification Configuration
export NOTIFICATION_EMAIL_FROM="build@example.com"
export NOTIFICATION_EMAIL_TO="$EMAIL_ID"
export NOTIFICATION_EMAIL_SUBJECT="Build Status"

# Print configuration status
echo "Balance variables loaded successfully"
echo "Note: These variables will be moved to database in future" 