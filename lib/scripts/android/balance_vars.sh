#!/bin/bash

# Ensure CM_BUILD_DIR is set
if [ -z "$CM_BUILD_DIR" ]; then
    CM_BUILD_DIR="$PWD"
fi

# Build Configuration
export BUILD_MODE="app-store"
export FLUTTER_VERSION="3.19.3"
export GRADLE_VERSION="8.2"
export JAVA_VERSION="17"

# Android Configuration
export ANDROID_COMPILE_SDK="34"
export ANDROID_MIN_SDK="21"
export ANDROID_TARGET_SDK="34"
export ANDROID_BUILD_TOOLS="34.0.0"
export ANDROID_NDK_VERSION="25.1.8937393"
export ANDROID_CMDLINE_TOOLS="9477386"

# Path Configuration
export PROJECT_ROOT="${CM_BUILD_DIR}"
export ANDROID_ROOT="${PROJECT_ROOT}/android"
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

# Asset Paths
export APP_ICON_PATH="${ASSETS_DIR}/app_icon.png"
export SPLASH_IMAGE_PATH="${ASSETS_DIR}/splash.png"
export SPLASH_BG_PATH="${ASSETS_DIR}/splash_bg.png"
export PUBSPEC_BACKUP_PATH="${PROJECT_ROOT}/pubspec.yaml.bak"

# Build Output Paths
export APK_OUTPUT_PATH="${OUTPUT_DIR}/app-release.apk"
export AAB_OUTPUT_PATH="${OUTPUT_DIR}/app-release.aab"

# Gradle Configuration
export GRADLE_WRAPPER_DIR="${ANDROID_ROOT}/gradle/wrapper"
export GRADLE_WRAPPER_JAR_PATH="${GRADLE_WRAPPER_DIR}/gradle-wrapper.jar"
export GRADLE_WRAPPER_PROPERTIES_PATH="${GRADLE_WRAPPER_DIR}/gradle-wrapper.properties"
export GRADLE_WRAPPER_URL="https://raw.githubusercontent.com/gradle/gradle/v${GRADLE_VERSION}/gradle/wrapper/gradle-wrapper.jar"
export GRADLE_DISTRIBUTION_URL="https\://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip"

# Download Configuration
export DOWNLOAD_MAX_RETRIES=3
export DOWNLOAD_RETRY_DELAY=5

# Notification Configuration
export NOTIFICATION_EMAIL_FROM="builds@example.com"
export NOTIFICATION_EMAIL_TO="team@example.com"
export NOTIFICATION_EMAIL_SUBJECT="Android Build Notification"