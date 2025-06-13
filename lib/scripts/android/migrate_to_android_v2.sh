#!/bin/bash

# Android V2 Embedding Migration Script
# This script ensures the Android project is properly configured for Flutter v2 embedding

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔄 Migrating to Android V2 Embedding...${NC}"

# Get the script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
ANDROID_ROOT="$PROJECT_ROOT/android"

# Get package name from environment or use default
PKG_NAME="${PKG_NAME:-com.garbcode.garbcodeapp}"
PACKAGE_PATH=$(echo "$PKG_NAME" | sed 's/\./\//g')

echo -e "${YELLOW}📦 Using package name: $PKG_NAME${NC}"
echo -e "${YELLOW}📁 Package path: $PACKAGE_PATH${NC}"

# Create the correct package directory structure
PACKAGE_DIR="$ANDROID_ROOT/app/src/main/kotlin/$PACKAGE_PATH"
mkdir -p "$PACKAGE_DIR"

echo -e "${BLUE}📁 Creating package directory: $PACKAGE_DIR${NC}"

# Create MainApplication.kt
cat > "$PACKAGE_DIR/MainApplication.kt" << EOF
package $PKG_NAME

import io.flutter.embedding.android.FlutterApplication
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant

class MainApplication : FlutterApplication() {
    override fun onCreate() {
        super.onCreate()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)
    }
}
EOF

echo -e "${GREEN}✅ Created MainApplication.kt${NC}"

# Update MainActivity.kt with correct package name
cat > "$PACKAGE_DIR/MainActivity.kt" << EOF
package $PKG_NAME

import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity()
EOF

echo -e "${GREEN}✅ Updated MainActivity.kt with correct package name${NC}"

# Remove old MainActivity if it exists in wrong location
OLD_MAIN_ACTIVITY="$ANDROID_ROOT/app/src/main/kotlin/com/example/quikapptest01/MainActivity.kt"
if [ -f "$OLD_MAIN_ACTIVITY" ]; then
    rm "$OLD_MAIN_ACTIVITY"
    echo -e "${YELLOW}🗑️  Removed old MainActivity.kt${NC}"
fi

# Update AndroidManifest.xml to include v2 embedding metadata
MANIFEST_FILE="$ANDROID_ROOT/app/src/main/AndroidManifest.xml"

# Create a backup of the manifest
cp "$MANIFEST_FILE" "$MANIFEST_FILE.backup"

# Update the manifest with proper v2 embedding configuration
cat > "$MANIFEST_FILE" << EOF
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="$PKG_NAME">

    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="29" />

    <application
        android:name=".MainApplication"
        android:label="Garbcode App"
        android:icon="@mipmap/ic_launcher"
        android:usesCleartextTraffic="true"
        android:theme="@style/LaunchTheme">

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">

            <meta-data
                android:name="io.flutter.embedding.android.NormalTheme"
                android:resource="@style/NormalTheme" />

            <intent-filter android:autoVerify="true">
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>

        </activity>

        <!-- Flutter V2 Embedding Metadata -->
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />

        <!-- Add other components like services or receivers here -->

    </application>
</manifest>
EOF

echo -e "${GREEN}✅ Updated AndroidManifest.xml with v2 embedding metadata${NC}"

# Update build.gradle.kts to use the correct package name
BUILD_GRADLE="$ANDROID_ROOT/app/build.gradle.kts"

if [ -f "$BUILD_GRADLE" ]; then
    # Update the namespace in build.gradle.kts
    sed -i.bak "s/namespace \".*\"/namespace \"$PKG_NAME\"/" "$BUILD_GRADLE"
    sed -i.bak "s/applicationId \".*\"/applicationId \"$PKG_NAME\"/" "$BUILD_GRADLE"
    
    echo -e "${GREEN}✅ Updated build.gradle.kts with correct package name${NC}"
fi

# Clean up backup files
rm -f "$MANIFEST_FILE.backup"
rm -f "$BUILD_GRADLE.bak"

echo -e "${GREEN}✅ Android V2 Embedding migration completed successfully!${NC}"
echo -e "${YELLOW}📋 Summary of changes:${NC}"
echo -e "   - Created MainApplication.kt in $PACKAGE_PATH"
echo -e "   - Updated MainActivity.kt with correct package name"
echo -e "   - Added v2 embedding metadata to AndroidManifest.xml"
echo -e "   - Updated package name in build.gradle.kts"
echo -e "   - Removed old MainActivity.kt from wrong location"

# Create output directory
OUTPUT_DIR="$PROJECT_ROOT/output"
mkdir -p "$OUTPUT_DIR"

# Move APK and AAB files to output directory
APK_FILE="$ANDROID_ROOT/app/build/outputs/apk/release/app-release.apk"
AAB_FILE="$ANDROID_ROOT/app/build/outputs/bundle/release/app-release.aab"

if [ -f "$APK_FILE" ]; then
    mv "$APK_FILE" "$OUTPUT_DIR"
    echo -e "${GREEN}✅ Moved APK file to output directory${NC}"
fi

if [ -f "$AAB_FILE" ]; then
    mv "$AAB_FILE" "$OUTPUT_DIR"
    echo -e "${GREEN}✅ Moved AAB file to output directory${NC}"
fi

echo -e "${GREEN}✅ Output files moved to $OUTPUT_DIR${NC}" 