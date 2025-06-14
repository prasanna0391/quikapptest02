#!/bin/bash
#!/usr/bin/env bash

# This script sets environment variables for local testing.
# These variables should match your Firebase configuration and app details.

# --- Firebase and App Identity Configuration ---
export PKG_NAME="${PKG_NAME:-com.garbcode.garbcodeapp}"
export APP_NAME="${APP_NAME:-Garbcode App}"
export ORG_NAME="${ORG_NAME:-Garbcode Apparels Private Limited}"
export VERSION_NAME="${VERSION_NAME:-1.0.22}"
export VERSION_CODE="${VERSION_CODE:-26}"
export EMAIL_ID="${EMAIL_ID:-prasannasrinivasan32@gmail.com}"

# --- Email Notification Configuration ---
# Uncomment and configure these variables to enable email sending
# For Gmail, use: smtp.gmail.com
# For Outlook, use: smtp-mail.outlook.com
# For Yahoo, use: smtp.mail.yahoo.com
export SMTP_SERVER="${SMTP_SERVER:-smtp.gmail.com}"
export SMTP_USERNAME="${SMTP_USERNAME:-prasannasrie@gmail.com}"
export SMTP_PASSWORD="${SMTP_PASSWORD:-jbbf nzhm zoay lbwb}"
# Note: For Gmail, you need to use an App Password, not your regular password
# To generate an App Password: Google Account > Security > 2-Step Verification > App passwords
# IMPORTANT: Replace "your-app-password" with your actual Gmail App Password

# --- Keystore Credentials (for inject_keystore.sh) ---
# Ensure this KEY_STORE URL is publicly accessible or adjust your download method.
export KEY_STORE="${KEY_STORE:-https://raw.githubusercontent.com/prasanna91/QuikApp/main/keystore.jks}"
export CM_KEYSTORE_PASSWORD="${CM_KEYSTORE_PASSWORD:-opeN@1234}"
export CM_KEY_ALIAS="${CM_KEY_ALIAS:-my_key_alias}"
export CM_KEY_PASSWORD="${CM_KEY_PASSWORD:-opeN@1234}"

# --- Firebase Config URLs (if PUSH_NOTIFY is true) ---
export PUSH_NOTIFY="${PUSH_NOTIFY:-true}" # Set to "false" if you are NOT using Firebase Push Notifications
if [ "$PUSH_NOTIFY" = "true" ]; then
    export firebase_config_android="${firebase_config_android:-https://raw.githubusercontent.com/prasanna91/QuikApp/main/google-services%20(gc).json}"
    export firebase_config_ios="${firebase_config_ios:-https://raw.githubusercontent.com/prasanna91/QuikApp/main/GoogleService-Info-gc.plist}"
    export APNS_KEY_ID="${APNS_KEY_ID:-V566SWNF69}"
    export APPLE_TEAM_ID="${APPLE_TEAM_ID:-9H2AD7NQ49}"
    export APNS_AUTH_KEY_URL="${APNS_AUTH_KEY_URL:-https://raw.githubusercontent.com/prasanna91/QuikApp/main/AuthKey_V566SWNF69.p8}"
else
    # Set empty values when push notifications are disabled
    export firebase_config_android="${firebase_config_android:-}"
    export firebase_config_ios="${firebase_config_ios:-}"
    export APNS_KEY_ID="${APNS_KEY_ID:-}"
    export APPLE_TEAM_ID="${APPLE_TEAM_ID:-}"
    export APNS_AUTH_KEY_URL="${APNS_AUTH_KEY_URL:-}"
fi

# --- Android SDK Versions (used by configure_android_build_fixed.sh, defaults are also provided) ---
export COMPILE_SDK_VERSION="${COMPILE_SDK_VERSION:-35}"
export MIN_SDK_VERSION="${MIN_SDK_VERSION:-21}"
export TARGET_SDK_VERSION="${TARGET_SDK_VERSION:-35}"

# --- Other Dart-Define variables (from your original build.sh) ---
export WEB_URL="${WEB_URL:-https://garbcode.com/}"
export IS_SPLASH="${IS_SPLASH:-true}"

# --- Splash Screen Configuration ---
if [ "$IS_SPLASH" = "true" ]; then
  export SPLASH="${SPLASH:-https://raw.githubusercontent.com/prasanna91/QuikApp/main/logo-gc.png}"
  export SPLASH_BG="${SPLASH_BG:-}"
  export SPLASH_ANIMATION="${SPLASH_ANIMATION:-zoom}"
  export SPLASH_BG_COLOR="${SPLASH_BG_COLOR:-#cbdbf5}"
  export SPLASH_TAGLINE="${SPLASH_TAGLINE:-Welcome to Garbcode}"
  export SPLASH_TAGLINE_COLOR="${SPLASH_TAGLINE_COLOR:-#a30237}"
  export SPLASH_DURATION="${SPLASH_DURATION:-4}"
else
  # Set empty values when splash is disabled
  export SPLASH="${SPLASH:-}"
  export SPLASH_BG="${SPLASH_BG:-}"
  export SPLASH_ANIMATION="${SPLASH_ANIMATION:-}"
  export SPLASH_BG_COLOR="${SPLASH_BG_COLOR:-}"
  export SPLASH_TAGLINE="${SPLASH_TAGLINE:-}"
  export SPLASH_TAGLINE_COLOR="${SPLASH_TAGLINE_COLOR:-}"
  export SPLASH_DURATION="${SPLASH_DURATION:-}"
fi

export IS_PULLDOWN="${IS_PULLDOWN:-true}"
export LOGO_URL="${LOGO_URL:-https://raw.githubusercontent.com/prasanna91/QuikApp/main/logo-gc.png}"

# --- Bottom Menu Configuration ---
export IS_BOTTOMMENU="${IS_BOTTOMMENU:-false}"

# Default bottom menu values (empty when disabled)
export BOTTOMMENU_BG_COLOR="${BOTTOMMENU_BG_COLOR:-}"
export BOTTOMMENU_ICON_COLOR="${BOTTOMMENU_ICON_COLOR:-}"
export BOTTOMMENU_TEXT_COLOR="${BOTTOMMENU_TEXT_COLOR:-}"
export BOTTOMMENU_FONT="${BOTTOMMENU_FONT:-}"
export BOTTOMMENU_FONT_SIZE="${BOTTOMMENU_FONT_SIZE:-}"
export BOTTOMMENU_FONT_BOLD="${BOTTOMMENU_FONT_BOLD:-}"
export BOTTOMMENU_FONT_ITALIC="${BOTTOMMENU_FONT_ITALIC:-}"
export BOTTOMMENU_ACTIVE_TAB_COLOR="${BOTTOMMENU_ACTIVE_TAB_COLOR:-}"
export BOTTOMMENU_ICON_POSITION="${BOTTOMMENU_ICON_POSITION:-}"
export BOTTOMMENU_VISIBLE_ON="${BOTTOMMENU_VISIBLE_ON:-}"
export BOTTOMMENU_ITEMS="${BOTTOMMENU_ITEMS:-}"

if [ "$IS_BOTTOMMENU" = "true" ]; then
  # Overwrite with actual values if IS_BOTTOMMENU is true
  export BOTTOMMENU_ITEMS="${BOTTOMMENU_ITEMS:-[{\"label\": \"Home\", \"icon\": \"home\", \"url\": \"https://pixaware.co/\"}, {\"label\": \"services\", \"icon\": \"services\", \"url\": \"https://pixaware.co/solutions/\"}, {\"label\": \"About\", \"icon\": \"info\", \"url\": \"https://pixaware.co/who-we-are/\"}, {\"label\": \"Contact\", \"icon\": \"phone\", \"url\": \"https://pixaware.co/lets-talk/\"}]}"
  export BOTTOMMENU_BG_COLOR="${BOTTOMMENU_BG_COLOR:-#FFFFFF}"
  export BOTTOMMENU_ICON_COLOR="${BOTTOMMENU_ICON_COLOR:-#6d6e8c}"
  export BOTTOMMENU_TEXT_COLOR="${BOTTOMMENU_TEXT_COLOR:-#6d6e8c}"
  export BOTTOMMENU_FONT="${BOTTOMMENU_FONT:-DM Sans}"
  export BOTTOMMENU_FONT_SIZE="${BOTTOMMENU_FONT_SIZE:-12}"
  export BOTTOMMENU_FONT_BOLD="${BOTTOMMENU_FONT_BOLD:-false}"
  export BOTTOMMENU_FONT_ITALIC="${BOTTOMMENU_FONT_ITALIC:-false}"
  export BOTTOMMENU_ACTIVE_TAB_COLOR="${BOTTOMMENU_ACTIVE_TAB_COLOR:-#a30237}"
  export BOTTOMMENU_ICON_POSITION="${BOTTOMMENU_ICON_POSITION:-above}"
  export BOTTOMMENU_VISIBLE_ON="${BOTTOMMENU_VISIBLE_ON:-home,settings,profile}"
fi

# --- Feature Flags ---
export IS_DEEPLINK="${IS_DEEPLINK:-true}"
export IS_LOAD_IND="${IS_LOAD_IND:-true}"
export IS_CHATBOT="${IS_CHATBOT:-true}"

# --- Permission Flags (with proper defaults and null handling) ---
export IS_CAMERA="${IS_CAMERA:-false}"
export IS_LOCATION="${IS_LOCATION:-false}"
export IS_BIOMETRIC="${IS_BIOMETRIC:-false}"
export IS_MIC="${IS_MIC:-true}"
export IS_CONTACT="${IS_CONTACT:-false}"
export IS_CALENDAR="${IS_CALENDAR:-false}"
export IS_NOTIFICATION="${IS_NOTIFICATION:-true}"
export IS_STORAGE="${IS_STORAGE:-true}"

# --- Flutter Configuration ---
export FLUTTER_ROOT="${FLUTTER_ROOT:-/Users/alakaraj/development/flutter}"

# --- Validation and Sanitization ---
# Ensure boolean values are properly formatted
for var in IS_CAMERA IS_LOCATION IS_BIOMETRIC IS_MIC IS_CONTACT IS_CALENDAR IS_NOTIFICATION IS_STORAGE IS_SPLASH IS_PULLDOWN IS_BOTTOMMENU IS_DEEPLINK IS_LOAD_IND IS_CHATBOT PUSH_NOTIFY; do
    # Convert various truthy/falsy values to true/false
    if [[ "${!var}" =~ ^(true|1|yes|on|enabled)$ ]]; then
        export "$var=true"
    elif [[ "${!var}" =~ ^(false|0|no|off|disabled|)$ ]]; then
        export "$var=false"
    else
        # Default to false for unknown values
        export "$var=false"
    fi
done

echo "Environment variables set for local testing."
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