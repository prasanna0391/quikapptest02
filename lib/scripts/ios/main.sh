#!/bin/bash
set -e

# Source environment variables
source "$(dirname "$0")/../export.sh"

echo "🚀 Starting iOS build process..."

# Validate required environment variables
if [ -z "$BUNDLE_ID" ] || [ -z "$APP_NAME" ] || [ -z "$VERSION_NAME" ] || [ -z "$VERSION_CODE" ]; then
    echo "❌ Missing required environment variables"
    exit 1
fi

# Create output directory
mkdir -p output

# Setup iOS code signing
echo "🔐 Setting up iOS code signing..."
KEYCHAIN_NAME="build.keychain"
KEYCHAIN_PASSWORD="temporary"

# Create keychain with better error handling
if ! security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_NAME"; then
    echo "⚠️  Keychain creation failed, trying with cleanup..."
    security delete-keychain "$KEYCHAIN_NAME" || true
    security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_NAME"
fi

security default-keychain -s "$KEYCHAIN_NAME"
security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_NAME"
security set-keychain-settings -t 3600 -u "$KEYCHAIN_NAME"

# Download and setup certificates with validation
if [ -n "$CERT_CER_URL" ] && [ -n "$CERT_KEY_URL" ]; then
    echo "📥 Downloading certificates..."
    
    if wget -O ios/distribution.cer "$CERT_CER_URL" && wget -O ios/privatekey.key "$CERT_KEY_URL"; then
        echo "✅ Certificates downloaded"
        
        # Convert to P12 with error handling
        if openssl pkcs12 -export -out ios/certificate.p12 -inkey ios/privatekey.key -in ios/distribution.cer -password pass:"$CERT_PASSWORD"; then
            echo "✅ P12 certificate created"
            
            # Import certificate
            if security import ios/certificate.p12 -k "$KEYCHAIN_NAME" -P "$CERT_PASSWORD" -T /usr/bin/codesign; then
                security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$KEYCHAIN_PASSWORD" "$KEYCHAIN_NAME"
                echo "✅ Certificate imported successfully"
            else
                echo "⚠️  Certificate import failed, continuing without code signing"
            fi
        else
            echo "⚠️  P12 conversion failed, continuing without code signing"
        fi
    else
        echo "⚠️  Certificate download failed, continuing without code signing"
    fi
fi

# Setup provisioning profile
if [ -n "$PROFILE_URL" ]; then
    echo "📥 Downloading provisioning profile..."
    if wget -O ios/profile.mobileprovision "$PROFILE_URL"; then
        mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
        
        # Extract profile info with error handling
        PROFILE_PLIST=$(mktemp)
        if security cms -D -i ios/profile.mobileprovision > "$PROFILE_PLIST"; then
            UUID=$(/usr/libexec/PlistBuddy -c "Print UUID" "$PROFILE_PLIST" 2>/dev/null || echo "")
            PROFILE_NAME=$(/usr/libexec/PlistBuddy -c "Print Name" "$PROFILE_PLIST" 2>/dev/null || echo "")
            
            if [ -n "$UUID" ] && [ -n "$PROFILE_NAME" ]; then
                cp ios/profile.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/"$UUID".mobileprovision
                echo "PROFILE_NAME=$PROFILE_NAME" >> $CM_ENV
                echo "PROFILE_UUID=$UUID" >> $CM_ENV
                echo "✅ Provisioning profile installed: $PROFILE_NAME"
            else
                echo "⚠️  Could not extract profile info, continuing..."
            fi
        else
            echo "⚠️  Profile parsing failed, continuing..."
        fi
        rm -f "$PROFILE_PLIST"
    else
        echo "⚠️  Profile download failed, continuing..."
    fi
fi

# Create ExportOptions.plist
cat > ExportOptions.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>$EXPORT_METHOD</string>
  <key>signingStyle</key>
  <string>manual</string>
  <key>teamID</key>
  <string>$APPLE_TEAM_ID</string>
  <key>provisioningProfiles</key>
  <dict>
    <key>$BUNDLE_ID</key>
    <string>\${PROFILE_NAME:-match AppStore $BUNDLE_ID}</string>
  </dict>
  <key>compileBitcode</key>
  <false/>
  <key>stripSwiftSymbols</key>
  <true/>
  <key>signingCertificate</key>
  <string>Apple Distribution</string>
  <key>uploadBitcode</key>
  <false/>
  <key>uploadSymbols</key>
  <true/>
</dict>
</plist>
EOF

# Build iOS with comprehensive dart-define and error handling
echo "🏗️ Building iOS app..."

if ! flutter build ios --release --no-codesign \
    --dart-define=PKG_NAME="$PKG_NAME" \
    --dart-define=BUNDLE_ID="$BUNDLE_ID" \
    --dart-define=APP_NAME="$APP_NAME" \
    --dart-define=ORG_NAME="$ORG_NAME" \
    --dart-define=VERSION_NAME="$VERSION_NAME" \
    --dart-define=VERSION_CODE="$VERSION_CODE" \
    --dart-define=PUSH_NOTIFY="$PUSH_NOTIFY" \
    --dart-define=firebase_config_ios="$firebase_config_ios" \
    --dart-define=WEB_URL="$WEB_URL" \
    --dart-define=IS_SPLASH="$IS_SPLASH" \
    --dart-define=SPLASH="$SPLASH" \
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
    --dart-define=IS_PHOTO_LIBRARY="$IS_PHOTO_LIBRARY" \
    --dart-define=IS_PHOTO_LIBRARY_ADD="$IS_PHOTO_LIBRARY_ADD" \
    --dart-define=IS_FACE_ID="$IS_FACE_ID" \
    --dart-define=IS_TOUCH_ID="$IS_TOUCH_ID"; then
    
    echo "❌ iOS build failed, trying with clean..."
    flutter clean
    cd ios && pod install && cd ..
    flutter pub get
    
    # Retry with minimal configuration
    flutter build ios --release --no-codesign \
        --dart-define=BUNDLE_ID="$BUNDLE_ID" \
        --dart-define=APP_NAME="$APP_NAME" \
        --dart-define=VERSION_NAME="$VERSION_NAME" \
        --dart-define=VERSION_CODE="$VERSION_CODE"
fi

# Archive and export IPA with better error handling
echo "📦 Archiving and exporting IPA..."

# Load environment variables for profile info
source $CM_ENV 2>/dev/null || true

# Archive with error handling
echo "🏗️ Creating Xcode archive..."
if xcodebuild -workspace ios/Runner.xcworkspace \
    -scheme Runner \
    -configuration Release \
    -archivePath build/ios/archive/Runner.xcarchive \
    clean archive \
    CODE_SIGN_STYLE=Manual \
    DEVELOPMENT_TEAM="$APPLE_TEAM_ID" \
    PROVISIONING_PROFILE_SPECIFIER="${PROFILE_NAME:-}" \
    PROVISIONING_PROFILE="${PROFILE_UUID:-}" \
    PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID" \
    CODE_SIGN_IDENTITY="Apple Distribution" \
    IPHONEOS_DEPLOYMENT_TARGET="$IPHONEOS_DEPLOYMENT_TARGET" \
    OTHER_CODE_SIGN_FLAGS="--keychain $KEYCHAIN_NAME"; then
    
    echo "✅ Archive created successfully"
    
    # Export IPA
    echo "📦 Exporting IPA..."
    if xcodebuild -exportArchive \
        -archivePath build/ios/archive/Runner.xcarchive \
        -exportPath build/ios/ipa \
        -exportOptionsPlist ExportOptions.plist; then
        
        echo "✅ IPA exported successfully"
    else
        echo "⚠️  IPA export failed, but archive was created"
    fi
else
    echo "❌ Archive creation failed"
    echo "📋 Available build products:"
    find build/ -name "*.app" -type d | head -5
fi

# Copy artifacts to output folder
echo "📁 Moving iOS artifacts..."
if [ -f "build/ios/ipa/Runner.ipa" ]; then
    cp build/ios/ipa/Runner.ipa output/
    echo "✅ IPA moved to output/"
else
    echo "⚠️  IPA not found, checking for .app files..."
    find build/ -name "*.app" -type d | head -1 | xargs -I {} cp -r {} output/ 2>/dev/null || true
fi

# Cleanup keychain
security delete-keychain "$KEYCHAIN_NAME" || true

echo "📋 Final iOS output contents:"
ls -la output/ || echo "No output directory" 