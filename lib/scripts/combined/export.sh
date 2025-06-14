#!/bin/bash

# App Configuration
export APP_NAME="${APP_NAME:-MyApp}"
export PKG_NAME="${PKG_NAME:-com.example.myapp}"
export BUNDLE_ID="${BUNDLE_ID:-com.example.myapp}"
export VERSION_NAME="${VERSION_NAME:-1.0.0}"
export VERSION_CODE="${VERSION_CODE:-1}"
export ORG_NAME="${ORG_NAME:-Example Org}"
export WEB_URL="${WEB_URL:-https://example.com}"

# Feature Flags
export PUSH_NOTIFY="${PUSH_NOTIFY:-false}"
export IS_CHATBOT="${IS_CHATBOT:-false}"
export IS_DEEPLINK="${IS_DEEPLINK:-false}"
export IS_SPLASH="${IS_SPLASH:-false}"
export IS_PULLDOWN="${IS_PULLDOWN:-false}"
export IS_BOTTOMMENU="${IS_BOTTOMMENU:-false}"
export IS_LOAD_IND="${IS_LOAD_IND:-false}"

# Assets
export LOGO_URL="${LOGO_URL:-}"
export SPLASH="${SPLASH:-}"
export SPLASH_BG="${SPLASH_BG:-}"
export SPLASH_BG_COLOR="${SPLASH_BG_COLOR:-#FFFFFF}"
export SPLASH_TAGLINE="${SPLASH_TAGLINE:-}"
export SPLASH_TAGLINE_COLOR="${SPLASH_TAGLINE_COLOR:-#000000}"
export SPLASH_ANIMATION="${SPLASH_ANIMATION:-fade}"
export SPLASH_DURATION="${SPLASH_DURATION:-2000}"

# Bottom Menu Configuration
export BOTTOMMENU_ITEMS="${BOTTOMMENU_ITEMS:-}"
export BOTTOMMENU_BG_COLOR="${BOTTOMMENU_BG_COLOR:-#FFFFFF}"
export BOTTOMMENU_ICON_COLOR="${BOTTOMMENU_ICON_COLOR:-#000000}"
export BOTTOMMENU_TEXT_COLOR="${BOTTOMMENU_TEXT_COLOR:-#000000}"
export BOTTOMMENU_FONT="${BOTTOMMENU_FONT:-Roboto}"
export BOTTOMMENU_FONT_SIZE="${BOTTOMMENU_FONT_SIZE:-12}"
export BOTTOMMENU_FONT_BOLD="${BOTTOMMENU_FONT_BOLD:-false}"
export BOTTOMMENU_FONT_ITALIC="${BOTTOMMENU_FONT_ITALIC:-false}"
export BOTTOMMENU_ACTIVE_TAB_COLOR="${BOTTOMMENU_ACTIVE_TAB_COLOR:-#0000FF}"
export BOTTOMMENU_ICON_POSITION="${BOTTOMMENU_ICON_POSITION:-top}"
export BOTTOMMENU_VISIBLE_ON="${BOTTOMMENU_VISIBLE_ON:-all}"

# Firebase Configuration
export FIREBASE_CONFIG_ANDROID="${FIREBASE_CONFIG_ANDROID:-}"
export FIREBASE_CONFIG_IOS="${FIREBASE_CONFIG_IOS:-}"

# iOS Configuration
export IPHONEOS_DEPLOYMENT_TARGET="${IPHONEOS_DEPLOYMENT_TARGET:-13.0}"
export COCOAPODS_PLATFORM="${COCOAPODS_PLATFORM:-ios}"
export EXPORT_METHOD="${EXPORT_METHOD:-app-store}"
export IS_DEVELOPMENT_PROFILE="${IS_DEVELOPMENT_PROFILE:-false}"
export IS_PRODUCTION_PROFILE="${IS_PRODUCTION_PROFILE:-true}"

# Android Configuration
export KEY_STORE="${KEY_STORE:-}"
export CM_KEYSTORE_PASSWORD="${CM_KEYSTORE_PASSWORD:-}"
export CM_KEY_ALIAS="${CM_KEY_ALIAS:-}"
export CM_KEY_PASSWORD="${CM_KEY_PASSWORD:-}"
export COMPILE_SDK_VERSION="${COMPILE_SDK_VERSION:-35}"
export MIN_SDK_VERSION="${MIN_SDK_VERSION:-21}"
export TARGET_SDK_VERSION="${TARGET_SDK_VERSION:-35}"

# Permissions
export IS_CAMERA="${IS_CAMERA:-false}"
export IS_LOCATION="${IS_LOCATION:-false}"
export IS_MIC="${IS_MIC:-false}"
export IS_NOTIFICATION="${IS_NOTIFICATION:-false}"
export IS_CONTACT="${IS_CONTACT:-false}"
export IS_BIOMETRIC="${IS_BIOMETRIC:-false}"
export IS_CALENDAR="${IS_CALENDAR:-false}"
export IS_STORAGE="${IS_STORAGE:-false}"

# iOS Permissions
export IS_PHOTO_LIBRARY="${IS_PHOTO_LIBRARY:-false}"
export IS_PHOTO_LIBRARY_ADD="${IS_PHOTO_LIBRARY_ADD:-false}"
export IS_FACE_ID="${IS_FACE_ID:-false}"
export IS_TOUCH_ID="${IS_TOUCH_ID:-false}"

# Email Configuration
export EMAIL_ID="${EMAIL_ID:-}"
export SMTP_SERVER="${SMTP_SERVER:-smtp.gmail.com}"
export SMTP_PORT="${SMTP_PORT:-587}"
export SMTP_USERNAME="${SMTP_USERNAME:-}"
export SMTP_PASSWORD="${SMTP_PASSWORD:-}"

# Print configuration summary
echo "📋 Configuration Summary:"
echo "========================"
echo "App: $APP_NAME ($VERSION_NAME-$VERSION_CODE)"
echo "Package: $PKG_NAME"
echo "Bundle ID: $BUNDLE_ID"
echo "Push Notifications: $PUSH_NOTIFY"
echo "Firebase: ${FIREBASE_CONFIG_ANDROID:+Android} ${FIREBASE_CONFIG_IOS:+iOS}"
echo "Build Type: ${EXPORT_METHOD:-release}"

echo "Environment variables set for combined build."
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