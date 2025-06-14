#!/usr/bin/env bash

set -euxo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Source environment variables
. "$SCRIPT_DIR/export.sh"

echo "🧹 Running flutter clean..."
flutter clean

# (Keystore setup removed; handled by inject_keystore.sh)

# Return to project root
cd "$PROJECT_ROOT"

echo "✅ Building APK..."
        flutter build apk --release \
            --dart-define=WEB_URL="$WEB_URL" \
            --dart-define=PUSH_NOTIFY="$PUSH_NOTIFY" \
            --dart-define=PKG_NAME="$PKG_NAME" \
            --dart-define=APP_NAME="$APP_NAME" \
            --dart-define=ORG_NAME="$ORG_NAME" \
            --dart-define=VERSION_NAME="$VERSION_NAME" \
            --dart-define=VERSION_CODE="$VERSION_CODE" \
            --dart-define=EMAIL_ID="$EMAIL_ID" \
            --dart-define=IS_SPLASH="$IS_SPLASH" \
            --dart-define=SPLASH="$SPLASH" \
            --dart-define=SPLASH_BG="$SPLASH_BG" \
            --dart-define=SPLASH_ANIMATION="$SPLASH_ANIMATION" \
            --dart-define=SPLASH_BG_COLOR="$SPLASH_BG_COLOR" \
            --dart-define=SPLASH_TAGLINE="$SPLASH_TAGLINE" \
            --dart-define=SPLASH_TAGLINE_COLOR="$SPLASH_TAGLINE_COLOR" \
            --dart-define=SPLASH_DURATION="$SPLASH_DURATION" \
            --dart-define=IS_PULLDOWN="$IS_PULLDOWN" \
            --dart-define=LOGO_URL="$LOGO_URL" \
            --dart-define=IS_BOTTOMMENU="$IS_BOTTOMMENU" \
            --dart-define=BOTTOMMENU_ITEMS="$BOTTOMMENU_ITEMS" \
            --dart-define=BOTTOMMENU_BG_COLOR="$BOTTOMMENU_BG_COLOR" \
            --dart-define=BOTTOMMENU_ICON_COLOR="$BOTTOMMENU_ICON_COLOR" \
            --dart-define=BOTTOMMENU_TEXT_COLOR="$BOTTOMMENU_TEXT_COLOR" \
            --dart-define=BOTTOMMENU_FONT="$BOTTOMMENU_FONT" \
            --dart-define=BOTTOMMENU_FONT_SIZE="$BOTTOMMENU_FONT_SIZE" \
            --dart-define=BOTTOMMENU_FONT_BOLD="$BOTTOMMENU_FONT_BOLD" \
            --dart-define=BOTTOMMENU_FONT_ITALIC="$BOTTOMMENU_FONT_ITALIC" \
            --dart-define=BOTTOMMENU_ACTIVE_TAB_COLOR="$BOTTOMMENU_ACTIVE_TAB_COLOR" \
            --dart-define=BOTTOMMENU_ICON_POSITION="$BOTTOMMENU_ICON_POSITION" \
            --dart-define=BOTTOMMENU_VISIBLE_ON="$BOTTOMMENU_VISIBLE_ON" \
            --dart-define=IS_DEEPLINK="$IS_DEEPLINK" \
            --dart-define=IS_LOAD_IND="$IS_LOAD_IND" \
            --dart-define=IS_CHATBOT="$IS_CHATBOT" \
            --dart-define=IS_CAMERA="$IS_CAMERA" \
            --dart-define=IS_LOCATION="$IS_LOCATION" \
            --dart-define=IS_BIOMETRIC="$IS_BIOMETRIC" \
            --dart-define=IS_MIC="$IS_MIC" \
            --dart-define=IS_CONTACT="$IS_CONTACT" \
            --dart-define=IS_CALENDAR="$IS_CALENDAR" \
            --dart-define=IS_NOTIFICATION="$IS_NOTIFICATION" \
            --dart-define=IS_STORAGE="$IS_STORAGE" \
            --dart-define=firebase_config_android="$firebase_config_android" \
            --dart-define=firebase_config_ios="$firebase_config_ios" \
            --dart-define=APNS_KEY_ID="$APNS_KEY_ID" \
            --dart-define=APPLE_TEAM_ID="$APPLE_TEAM_ID" \
            --dart-define=APNS_AUTH_KEY_URL="$APNS_AUTH_KEY_URL" \
            2>&1 | tee flutter_build_apk.log || true
        
        # Check if APK files were actually generated
        if [ -f "android/app/build/outputs/flutter-apk/app-release.apk" ] || [ -f "android/app/build/outputs/apk/release/app-release.apk" ] || [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
            echo "✅ APK build completed successfully - APK files found!"
            # Copy APK to output directory for easier access
            mkdir -p output
            if [ -f "android/app/build/outputs/flutter-apk/app-release.apk" ]; then
                cp "android/app/build/outputs/flutter-apk/app-release.apk" "output/"
                echo "✅ APK copied to output/app-release.apk"
            elif [ -f "android/app/build/outputs/apk/release/app-release.apk" ]; then
                cp "android/app/build/outputs/apk/release/app-release.apk" "output/"
                echo "✅ APK copied to output/app-release.apk"
            elif [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
                cp "build/app/outputs/flutter-apk/app-release.apk" "output/"
                echo "✅ APK copied to output/app-release.apk"
            fi
        else
            echo "❌ APK build failed - no APK files found. See flutter_build_apk.log for details."
            echo "🔍 Checking for APK files in common locations..."
            find . -name "*.apk" -type f 2>/dev/null | head -10
            exit 1
        fi

        echo "✅ Building AppBundle..."
        flutter build appbundle --release \
            --dart-define=WEB_URL="$WEB_URL" \
            --dart-define=PUSH_NOTIFY="$PUSH_NOTIFY" \
            --dart-define=PKG_NAME="$PKG_NAME" \
            --dart-define=APP_NAME="$APP_NAME" \
            --dart-define=ORG_NAME="$ORG_NAME" \
            --dart-define=VERSION_NAME="$VERSION_NAME" \
            --dart-define=VERSION_CODE="$VERSION_CODE" \
            --dart-define=EMAIL_ID="$EMAIL_ID" \
            --dart-define=IS_SPLASH="$IS_SPLASH" \
            --dart-define=SPLASH="$SPLASH" \
            --dart-define=SPLASH_BG="$SPLASH_BG" \
            --dart-define=SPLASH_ANIMATION="$SPLASH_ANIMATION" \
            --dart-define=SPLASH_BG_COLOR="$SPLASH_BG_COLOR" \
            --dart-define=SPLASH_TAGLINE="$SPLASH_TAGLINE" \
            --dart-define=SPLASH_TAGLINE_COLOR="$SPLASH_TAGLINE_COLOR" \
            --dart-define=SPLASH_DURATION="$SPLASH_DURATION" \
            --dart-define=IS_PULLDOWN="$IS_PULLDOWN" \
            --dart-define=LOGO_URL="$LOGO_URL" \
            --dart-define=IS_BOTTOMMENU="$IS_BOTTOMMENU" \
            --dart-define=BOTTOMMENU_ITEMS="$BOTTOMMENU_ITEMS" \
            --dart-define=BOTTOMMENU_BG_COLOR="$BOTTOMMENU_BG_COLOR" \
            --dart-define=BOTTOMMENU_ICON_COLOR="$BOTTOMMENU_ICON_COLOR" \
            --dart-define=BOTTOMMENU_TEXT_COLOR="$BOTTOMMENU_TEXT_COLOR" \
            --dart-define=BOTTOMMENU_FONT="$BOTTOMMENU_FONT" \
            --dart-define=BOTTOMMENU_FONT_SIZE="$BOTTOMMENU_FONT_SIZE" \
            --dart-define=BOTTOMMENU_FONT_BOLD="$BOTTOMMENU_FONT_BOLD" \
            --dart-define=BOTTOMMENU_FONT_ITALIC="$BOTTOMMENU_FONT_ITALIC" \
            --dart-define=BOTTOMMENU_ACTIVE_TAB_COLOR="$BOTTOMMENU_ACTIVE_TAB_COLOR" \
            --dart-define=BOTTOMMENU_ICON_POSITION="$BOTTOMMENU_ICON_POSITION" \
            --dart-define=BOTTOMMENU_VISIBLE_ON="$BOTTOMMENU_VISIBLE_ON" \
            --dart-define=IS_DEEPLINK="$IS_DEEPLINK" \
            --dart-define=IS_LOAD_IND="$IS_LOAD_IND" \
            --dart-define=IS_CHATBOT="$IS_CHATBOT" \
            --dart-define=IS_CAMERA="$IS_CAMERA" \
            --dart-define=IS_LOCATION="$IS_LOCATION" \
            --dart-define=IS_BIOMETRIC="$IS_BIOMETRIC" \
            --dart-define=IS_MIC="$IS_MIC" \
            --dart-define=IS_CONTACT="$IS_CONTACT" \
            --dart-define=IS_CALENDAR="$IS_CALENDAR" \
            --dart-define=IS_NOTIFICATION="$IS_NOTIFICATION" \
            --dart-define=IS_STORAGE="$IS_STORAGE" \
            --dart-define=firebase_config_android="$firebase_config_android" \
            --dart-define=firebase_config_ios="$firebase_config_ios" \
            --dart-define=APNS_KEY_ID="$APNS_KEY_ID" \
            --dart-define=APPLE_TEAM_ID="$APPLE_TEAM_ID" \
            --dart-define=APNS_AUTH_KEY_URL="$APNS_AUTH_KEY_URL" \
            2>&1 | tee flutter_build_aab.log || true
        
        # Check if AAB files were actually generated
        if [ -f "android/app/build/outputs/bundle/release/app-release.aab" ]; then
            echo "✅ AppBundle build completed successfully - AAB file found!"
            # Copy AAB to output directory for easier access
            mkdir -p output
            cp "android/app/build/outputs/bundle/release/app-release.aab" "output/"
            echo "✅ AAB copied to output/app-release.aab"
        else
            echo "❌ AppBundle build failed - no AAB file found. See flutter_build_aab.log for details."
            echo "🔍 Checking for AAB files in common locations..."
            find . -name "*.aab" -type f 2>/dev/null | head -10
            exit 1
        fi