#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Function to handle errors
handle_error() {
    local error_msg="$1"
    echo "❌ Error: $error_msg"
    bash "$(dirname "$0")/send_error_email.sh" "Configuration Failed" "$error_msg"
    exit 1
}

# Function to update app name
update_app_name() {
    echo "📝 Updating app name..."
    
    # Update Android app name
    if [ -f "android/app/src/main/AndroidManifest.xml" ]; then
        sed -i.bak "s/android:label=\".*\"/android:label=\"$APP_NAME\"/" android/app/src/main/AndroidManifest.xml
    fi
    
    # Update iOS app name
    if [ -f "ios/Runner/Info.plist" ]; then
        /usr/libexec/PlistBuddy -c "Set :CFBundleName $APP_NAME" ios/Runner/Info.plist
        /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName $APP_NAME" ios/Runner/Info.plist
    fi
    
    echo "✅ App name updated"
}

# Function to update package name
update_package_name() {
    echo "📝 Updating package name..."
    
    # Update Android package name
    if [ -f "android/app/build.gradle" ]; then
        sed -i.bak "s/applicationId \".*\"/applicationId \"$PKG_NAME\"/" android/app/build.gradle
    fi
    
    # Update iOS bundle identifier
    if [ -f "ios/Runner.xcodeproj/project.pbxproj" ]; then
        sed -i.bak "s/PRODUCT_BUNDLE_IDENTIFIER = \".*\";/PRODUCT_BUNDLE_IDENTIFIER = \"$BUNDLE_ID\";/" ios/Runner.xcodeproj/project.pbxproj
    fi
    
    echo "✅ Package name updated"
}

# Function to update app icons
update_app_icons() {
    echo "🎨 Updating app icons..."
    
    # Create pubspec.yaml entry for flutter_launcher_icons
    if [ -n "$LOGO_URL" ]; then
        cat >> pubspec.yaml << EOF

flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon/icon.png"
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "assets/icon/icon_foreground.png"
EOF
        
        # Download and save icon
        mkdir -p assets/icon
        wget -O assets/icon/icon.png "$LOGO_URL" || handle_error "Failed to download app icon"
        
        # Run flutter_launcher_icons
        flutter pub add flutter_launcher_icons
        flutter pub run flutter_launcher_icons
    fi
    
    echo "✅ App icons updated"
}

# Function to update splash screen
update_splash_screen() {
    echo "🎨 Updating splash screen..."
    
    if [ "$IS_SPLASH" = "true" ] && [ -n "$SPLASH" ]; then
        # Create pubspec.yaml entry for flutter_native_splash
        cat >> pubspec.yaml << EOF

flutter_native_splash:
  color: "$SPLASH_BG_COLOR"
  image: assets/splash/splash.png
  android: true
  ios: true
  web: false
EOF
        
        # Download and save splash image
        mkdir -p assets/splash
        wget -O assets/splash/splash.png "$SPLASH" || handle_error "Failed to download splash image"
        
        # Run flutter_native_splash
        flutter pub add flutter_native_splash
        flutter pub run flutter_native_splash:create
    fi
    
    echo "✅ Splash screen updated"
}

# Function to update bottom menu
update_bottom_menu() {
    echo "🎨 Updating bottom menu..."
    
    if [ "$IS_BOTTOMMENU" = "true" ] && [ -n "$BOTTOMMENU_ITEMS" ]; then
        # Create bottom menu configuration
        mkdir -p lib/config
        cat > lib/config/bottom_menu.dart << EOF
import 'package:flutter/material.dart';

class BottomMenuConfig {
  static const List<Map<String, dynamic>> items = $BOTTOMMENU_ITEMS;
  static const Color backgroundColor = Color(0x$BOTTOMMENU_BG_COLOR);
  static const Color iconColor = Color(0x$BOTTOMMENU_ICON_COLOR);
  static const Color textColor = Color(0x$BOTTOMMENU_TEXT_COLOR);
  static const String fontFamily = '$BOTTOMMENU_FONT';
  static const double fontSize = $BOTTOMMENU_FONT_SIZE;
  static const bool isBold = $BOTTOMMENU_FONT_BOLD;
  static const bool isItalic = $BOTTOMMENU_FONT_ITALIC;
  static const Color activeTabColor = Color(0x$BOTTOMMENU_ACTIVE_TAB_COLOR);
  static const String iconPosition = '$BOTTOMMENU_ICON_POSITION';
  static const String visibleOn = '$BOTTOMMENU_VISIBLE_ON';
}
EOF
    fi
    
    echo "✅ Bottom menu updated"
}

# Main configuration process
echo "🚀 Starting app configuration..."

update_app_name
update_package_name
update_app_icons
update_splash_screen
update_bottom_menu

echo "✅ App configuration completed successfully" 