#!/bin/bash

# Ensure CM_BUILD_DIR is set
if [ -z "$CM_BUILD_DIR" ]; then
    CM_BUILD_DIR="$PWD"
fi

# Build Configuration
export BUILD_MODE="app-store"
export FLUTTER_VERSION="3.19.3"
export GRADLE_VERSION="7.6.3"
export JAVA_VERSION="11"
export XCODE_VERSION="15.0"
export SWIFT_VERSION="5.0"

# Android Configuration
export ANDROID_COMPILE_SDK="33"
export ANDROID_MIN_SDK="21"
export ANDROID_TARGET_SDK="33"
export ANDROID_BUILD_TOOLS="33.0.0"
export ANDROID_NDK_VERSION="25.1.8937393"
export ANDROID_CMDLINE_TOOLS="9477386"

# iOS Configuration
export IOS_DEPLOYMENT_TARGET="12.0"
export IOS_BUILD_SDK="17.0"
export IOS_SIMULATOR_SDK="17.0"
export IOS_ARCHIVE_PATH="build/ios/archive/Runner.xcarchive"
export IOS_EXPORT_PATH="build/ios/ipa"

# Path Configuration
export PROJECT_ROOT="${CM_BUILD_DIR}"
export ANDROID_ROOT="${PROJECT_ROOT}/android"
export IOS_ROOT="${PROJECT_ROOT}/ios"
export ASSETS_DIR="${PROJECT_ROOT}/assets"
export OUTPUT_DIR="${PROJECT_ROOT}/build/outputs"
export TEMP_DIR="${PROJECT_ROOT}/build/temp"

# Android Paths
export ANDROID_MANIFEST_PATH="${ANDROID_ROOT}/app/src/main/AndroidManifest.xml"
export ANDROID_BUILD_GRADLE_PATH="${ANDROID_ROOT}/app/build.gradle"
export ANDROID_LOCAL_PROPERTIES_PATH="${ANDROID_ROOT}/local.properties"
export ANDROID_KEY_PROPERTIES_PATH="${ANDROID_ROOT}/key.properties"
export ANDROID_KEYSTORE_PATH="${ANDROID_ROOT}/app/keystore.jks"
export ANDROID_FIREBASE_CONFIG_PATH="${ANDROID_ROOT}/app/google-services.json"
export ANDROID_MIPMAP_DIR="${ANDROID_ROOT}/app/src/main/res/mipmap"
export ANDROID_DRAWABLE_DIR="${ANDROID_ROOT}/app/src/main/res/drawable"

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
export APK_OUTPUT_PATH="${OUTPUT_DIR}/app-release.apk"
export AAB_OUTPUT_PATH="${OUTPUT_DIR}/app-release.aab"
export IPA_OUTPUT_PATH="${OUTPUT_DIR}/Runner.ipa"
export APP_OUTPUT_PATH="${OUTPUT_DIR}/Runner.app"

# Gradle Configuration
export GRADLE_WRAPPER_DIR="${ANDROID_ROOT}/gradle/wrapper"
export GRADLE_WRAPPER_JAR_PATH="${GRADLE_WRAPPER_DIR}/gradle-wrapper.jar"
export GRADLE_WRAPPER_PROPERTIES_PATH="${GRADLE_WRAPPER_DIR}/gradle-wrapper.properties"
export GRADLE_WRAPPER_URL="https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-wrapper.jar"
export GRADLE_DISTRIBUTION_URL="https\://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip"

# Download Configuration
export DOWNLOAD_MAX_RETRIES=3
export DOWNLOAD_RETRY_DELAY=5

# Notification Configuration
export NOTIFICATION_EMAIL_FROM="builds@example.com"
export NOTIFICATION_EMAIL_TO="team@example.com"
export NOTIFICATION_EMAIL_SUBJECT="Combined Build Notification"

# Android Keystore Configuration
export ANDROID_KEYSTORE_BASE64=""  # Set this if you have a base64-encoded keystore
export KEYSTORE_FILE="keystore.jks"
export KEYSTORE_PASSWORD="android"
export KEY_ALIAS="androiddebugkey"
export KEY_PASSWORD="android"

# iOS Keystore Configuration
export IOS_CERTIFICATE_BASE64=""  # Set this if you have a base64-encoded certificate
export IOS_PROVISIONING_PROFILE_BASE64=""  # Set this if you have a base64-encoded provisioning profile
export IOS_CERTIFICATE_PASSWORD=""  # Set this if your certificate is password protected

# Firebase Configuration
export FIREBASE_CONFIG_URL=""  # Set this if you have a Firebase config URL
export FIREBASE_ENABLED=false  # Set to true if Firebase is enabled

# Print configuration status
echo "Balance variables loaded successfully"
echo "Note: These variables will be moved to database in future" 