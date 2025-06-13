#!/usr/bin/env bash
set -euo pipefail
trap 'echo "❌ Error on line $LINENO"; exit 1' ERR

echo "*********** App Name & Version ***********"
echo "APP_NAME: ${APP_NAME:-NULL}"
echo "ORG_NAME: ${ORG_NAME:-NULL}"
echo "WEB_URL: ${WEB_URL:-NULL}"
echo "VERSION_NAME: ${VERSION_NAME:-NULL}"
echo "VERSION_CODE: ${VERSION_CODE:-NULL}"
echo "PKG_NAME: ${PKG_NAME:-NULL}"
echo "BUNDLE_ID: ${BUNDLE_ID:-NULL}"

echo "*********** App Permissions ***********"
echo "IS_CAMERA: ${IS_CAMERA:-NULL}"
echo "IS_LOCATION: ${IS_LOCATION:-NULL}"
echo "IS_MIC: ${IS_MIC:-NULL}"
echo "IS_NOTIFICATION: ${IS_NOTIFICATION:-NULL}"
echo "IS_CONTACT: ${IS_CONTACT:-NULL}"
echo "IS_BIOMETRIC: ${IS_BIOMETRIC:-NULL}"
echo "IS_CALENDAR: ${IS_CALENDAR:-NULL}"

echo "*********** App Customization Configuration ***********"
echo "Splash Screen: ${IS_SPLASH:-NULL}"
echo "Pull To Refresh: ${IS_PULLDOWN:-NULL}"
echo "Loading Indicators: ${IS_LOAD_IND:-NULL}"
echo "Bottom Navigation Bar: ${IS_BOTTOMMENU:-NULL}"
echo "Deep Linking: ${IS_DEEPLINK:-NULL}"

echo "*********** Push Notification Configuration ***********"
echo "PUSH_NOTIFY: ${PUSH_NOTIFY:-NULL}"
echo "IS_CHATBOT: ${IS_CHATBOT:-NULL}"

echo "*********** Android Keystore ***********"
echo "KEY_STORE: ${KEY_STORE:-NULL}"
echo "CM_KEYSTORE_PASSWORD: ${CM_KEYSTORE_PASSWORD:-NULL}"
echo "CM_KEY_ALIAS: ${CM_KEY_ALIAS:-NULL}"
echo "CM_KEY_PASSWORD: ${CM_KEY_PASSWORD:-NULL}"

echo "*********** IOS Keystore ***********"
echo "TEAM_ID: ${APPLE_TEAM_ID:-NULL}"
echo "Apple Distribution Certificate URL: ${CERT_CER_URL:-NULL}" # CORRECTED LINE
echo "Apple Distribution Certificate Password: ${CERT_PASSWORD:-NULL}"
echo "Apple Distribution Profile URL: ${PROFILE_URL:-NULL}"
echo "APP_STORE_CONNECT_PRIVATE_KEY: ${CERT_KEY_URL:-NULL}"

# Removed APP_STORE_CONNECT_ISSUER_ID as it's not exported in export.sh
echo "APP_STORE_CONNECT_KEY_IDENTIFIER: ${APP_STORE_CONNECT_KEY_IDENTIFIER:-NULL}"
echo "APNS_KEY_ID: ${APNS_KEY_ID:-NULL}"
echo "APNS_AUTH_KEY_URL: ${APNS_AUTH_KEY_URL:-NULL}"

echo "*********** Firebase Android config file ***********"
echo "firebase_config_android: ${firebase_config_android:-NULL}"

echo "*********** Firebase IOS config file ***********"
echo "firebase_config_ios: ${firebase_config_ios:-NULL}"

echo "*********** Splash Configuration ***********"
echo "SPLASH: ${SPLASH:-NULL}"
echo "SPLASH_BG: ${SPLASH_BG:-NULL}"
echo "SPLASH_BG_COLOR: ${SPLASH_BG_COLOR:-NULL}"
echo "SPLASH_TAGLINE: ${SPLASH_TAGLINE:-NULL}"
echo "SPLASH_TAGLINE_COLOR: ${SPLASH_TAGLINE_COLOR:-NULL}"
echo "SPLASH_ANIMATION: ${SPLASH_ANIMATION:-NULL}"
echo "SPLASH_DURATION: ${SPLASH_DURATION:-NULL}"

echo "*********** Bottom Navigation Configuration ***********"
echo "BOTTOMMENU_ITEMS: ${BOTTOMMENU_ITEMS:-NULL}"
echo "BOTTOMMENU_BG_COLOR: ${BOTTOMMENU_BG_COLOR:-NULL}"
echo "BOTTOMMENU_ICON_COLOR: ${BOTTOMMENU_ICON_COLOR:-NULL}"
echo "BOTTOMMENU_TEXT_COLOR: ${BOTTOMMENU_TEXT_COLOR:-NULL}"
echo "BOTTOMMENU_FONT: ${BOTTOMMENU_FONT:-NULL}"
echo "BOTTOMMENU_FONT_SIZE: ${BOTTOMMENU_FONT_SIZE:-NULL}"
echo "BOTTOMMENU_FONT_BOLD: ${BOTTOMMENU_FONT_BOLD:-NULL}"
echo "BOTTOMMENU_FONT_ITALIC: ${BOTTOMMENU_FONT_ITALIC:-NULL}"
echo "BOTTOMMENU_ACTIVE_TAB_COLOR: ${BOTTOMMENU_ACTIVE_TAB_COLOR:-NULL}"
echo "BOTTOMMENU_ICON_POSITION: ${BOTTOMMENU_ICON_POSITION:-NULL}"
echo "BOTTOMMENU_VISIBLE_ON: ${BOTTOMMENU_VISIBLE_ON:-NULL}"

echo "*********** Publish Configuration ***********"
echo "EMAIL_ID: ${EMAIL_ID:-NULL}"