#!/bin/bash

# Test Error Email Notification Script
# This script tests the error email notification functionality

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}🧪 Testing Error Email Notification System${NC}"
echo "=============================================="

# Import environment variables
echo -e "${BLUE}📋 Loading environment variables...${NC}"
. "$SCRIPT_DIR/export.sh"

echo -e "${GREEN}✅ Environment variables loaded${NC}"
echo -e "${BLUE}📧 Recipient email: ${EMAIL_ID:-prasannasrie@gmail.com}${NC}"
echo ""

# Test different error scenarios
echo -e "${BLUE}🧪 Testing different error scenarios...${NC}"

# Test 1: V1 Embedding Error
echo -e "${YELLOW}Test 1: V1 Embedding Error${NC}"
"$SCRIPT_DIR/send_error_email.sh" \
    "Android v1 embedding detected - FlutterApplication is deprecated" \
    "Error: io.flutter.app.FlutterApplication is not available in Flutter v2 embedding.
Please update MainApplication.kt to use android.app.Application instead.
File: android/app/src/main/kotlin/com/garbcode/garbcodeapp/MainApplication.kt
Line: 5: class MainApplication : FlutterApplication()"

echo ""

# Test 2: Missing Resource Error
echo -e "${YELLOW}Test 2: Missing Resource Error${NC}"
"$SCRIPT_DIR/send_error_email.sh" \
    "Missing resource file - ic_launcher_round not found" \
    "ERROR: /Users/alakaraj/workspace/quikapptest01/android/app/src/main/AndroidManifest.xml:6:5-41:19: AAPT: error: resource mipmap/ic_launcher_round (aka com.garbcode.garbcodeapp:mipmap/ic_launcher_round) not found."

echo ""

# Test 3: Google Services Error
echo -e "${YELLOW}Test 3: Google Services Error${NC}"
"$SCRIPT_DIR/send_error_email.sh" \
    "Google Services configuration error - package name mismatch" \
    "File google-services.json is configured for package name 'com.example.app' but the current package name is 'com.garbcode.garbcodeapp'.
Please update google-services.json with the correct package name or update your app's package name to match."

echo ""

# Test 4: Compilation Error
echo -e "${YELLOW}Test 4: Compilation Error${NC}"
"$SCRIPT_DIR/send_error_email.sh" \
    "Kotlin compilation failed - missing import" \
    "e: /Users/alakaraj/workspace/quikapptest01/android/app/src/main/kotlin/com/garbcode/garbcodeapp/MainActivity.kt:3:8: Unresolved reference: io.flutter.app
import io.flutter.app.FlutterActivity
       ^
Please add the correct import statement or update to use v2 embedding."

echo ""

# Test 5: Gradle Error
echo -e "${YELLOW}Test 5: Gradle Error${NC}"
"$SCRIPT_DIR/send_error_email.sh" \
    "Gradle build failed - dependency conflict" \
    "FAILURE: Build failed with an exception.
* What went wrong:
Execution failed for task ':app:processReleaseResources'.
> A failure occurred while executing com.android.build.gradle.internal.res.LinkApplicationAndroidResourcesTask\$TaskAction
   > Android resource linking failed
     ERROR: In <declare-styleable> FontFamilyFont, unable to find attribute android:font
     ERROR: In <declare-styleable> FontFamilyFont, unable to find attribute android:fontStyle
     ERROR: In <declare-styleable> FontFamilyFont, unable to find attribute android:fontWeight"

echo ""

# Test 6: Unknown Error
echo -e "${YELLOW}Test 6: Unknown Error${NC}"
"$SCRIPT_DIR/send_error_email.sh" \
    "Unknown build error occurred" \
    "An unexpected error occurred during the build process. Please check the build logs for more details."

echo ""
echo -e "${GREEN}🎉 All error email tests completed!${NC}"
echo "=============================================="
echo -e "${BLUE}📄 Check the project root directory for generated email HTML files${NC}"
echo -e "${BLUE}📧 Email notifications would be sent to: ${EMAIL_ID:-prasannasrie@gmail.com}${NC}"
echo ""
echo -e "${YELLOW}💡 Note: These are test emails. In a real implementation, you would configure${NC}"
echo -e "${YELLOW}   an email service (SendGrid, Mailgun, SMTP, etc.) to actually send the emails.${NC}" 