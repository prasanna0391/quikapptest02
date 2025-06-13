#!/bin/bash

# Function to set default values if not provided
set_default() {
    local var_name=$1
    local default_value=$2
    if [ -z "${!var_name}" ]; then
        export "$var_name=$default_value"
    fi
}

# API Variables (from Codemagic)
# These will be set by Codemagic during build
# For local testing, they can be set in local.env

# App Configuration
set_default "VERSION_NAME" "1.0.0"
set_default "VERSION_CODE" "1"
set_default "APP_NAME" "QuikApp"
set_default "ORG_NAME" "QuikApp Organization"
set_default "WEB_URL" "https://example.com/"
set_default "PKG_NAME" "com.example.app"
set_default "BUNDLE_ID" "com.example.app"
set_default "EMAIL_ID" "admin@example.com"

# Feature Flags
set_default "PUSH_NOTIFY" "false"
set_default "IS_CHATBOT" "false"
set_default "IS_DEEPLINK" "false"
set_default "IS_SPLASH" "false"
set_default "IS_PULLDOWN" "false"
set_default "IS_BOTTOMMENU" "false"
set_default "IS_LOAD_IND" "false"

# Permissions
set_default "IS_CAMERA" "false"
set_default "IS_LOCATION" "false"
set_default "IS_MIC" "false"
set_default "IS_NOTIFICATION" "false"
set_default "IS_CONTACT" "false"
set_default "IS_BIOMETRIC" "false"
set_default "IS_CALENDAR" "false"
set_default "IS_STORAGE" "true"

# Assets
set_default "LOGO_URL" ""
set_default "SPLASH" ""
set_default "SPLASH_BG" ""
set_default "SPLASH_BG_COLOR" "#FFFFFF"
set_default "SPLASH_TAGLINE" ""
set_default "SPLASH_TAGLINE_COLOR" "#000000"
set_default "SPLASH_ANIMATION" "fade"
set_default "SPLASH_DURATION" "3"

# Bottom Menu Configuration
set_default "BOTTOMMENU_ITEMS" "[]"
set_default "BOTTOMMENU_BG_COLOR" "#FFFFFF"
set_default "BOTTOMMENU_ICON_COLOR" "#000000"
set_default "BOTTOMMENU_TEXT_COLOR" "#000000"
set_default "BOTTOMMENU_FONT" "System"
set_default "BOTTOMMENU_FONT_SIZE" "12"
set_default "BOTTOMMENU_FONT_BOLD" "false"
set_default "BOTTOMMENU_FONT_ITALIC" "false"
set_default "BOTTOMMENU_ACTIVE_TAB_COLOR" "#007AFF"
set_default "BOTTOMMENU_ICON_POSITION" "above"
set_default "BOTTOMMENU_VISIBLE_ON" ""

# Firebase Configuration
set_default "firebase_config_android" ""
set_default "firebase_config_ios" ""

# iOS Configuration
set_default "APPLE_TEAM_ID" ""
set_default "APNS_KEY_ID" ""
set_default "APNS_AUTH_KEY_URL" ""
set_default "CERT_PASSWORD" ""
set_default "PROFILE_URL" ""
set_default "CERT_CER_URL" ""
set_default "CERT_KEY_URL" ""
set_default "APP_STORE_CONNECT_KEY_IDENTIFIER" ""
set_default "IPHONEOS_DEPLOYMENT_TARGET" "13.0"
set_default "COCOAPODS_PLATFORM" "ios"
set_default "EXPORT_METHOD" "app-store-connect"
set_default "IS_DEVELOPMENT_PROFILE" "false"
set_default "IS_PRODUCTION_PROFILE" "true"

# Android Configuration
set_default "KEY_STORE" ""
set_default "CM_KEYSTORE_PASSWORD" ""
set_default "CM_KEY_ALIAS" ""
set_default "CM_KEY_PASSWORD" ""
set_default "COMPILE_SDK_VERSION" "35"
set_default "MIN_SDK_VERSION" "21"
set_default "TARGET_SDK_VERSION" "35"

# iOS Permissions
set_default "IS_PHOTO_LIBRARY" "false"
set_default "IS_PHOTO_LIBRARY_ADD" "false"
set_default "IS_FACE_ID" "false"
set_default "IS_TOUCH_ID" "false"

# Email Configuration
set_default "SMTP_SERVER" "smtp.gmail.com"
set_default "SMTP_PORT" "587"
set_default "SMTP_USERNAME" ""
set_default "SMTP_PASSWORD" ""

# Print configuration summary
echo "📋 Configuration Summary:"
echo "  📱 App: $APP_NAME ($PKG_NAME) v$VERSION_NAME"
echo "  🔔 Push Notifications: $PUSH_NOTIFY"
echo "  🎨 Splash Screen: $IS_SPLASH"
echo "  📱 Bottom Menu: $IS_BOTTOMMENU"
echo "  📧 Email: $EMAIL_ID"
echo ""
echo "🔐 Permissions:"
echo "  📷 Camera: $IS_CAMERA"
echo "  📍 Location: $IS_LOCATION"
echo "  🔐 Biometric: $IS_BIOMETRIC"
echo "  🎤 Microphone: $IS_MIC"
echo "  👥 Contacts: $IS_CONTACT"
echo "  📅 Calendar: $IS_CALENDAR"
echo "  🔔 Notifications: $IS_NOTIFICATION"
echo "  💾 Storage: $IS_STORAGE" 