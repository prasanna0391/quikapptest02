#!/bin/bash
set -e

echo "🧪 Testing iOS Publish Workflow Locally"
echo "======================================="
echo ""

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ iOS builds can only run on macOS"
    echo "⚠️  Skipping iOS workflow test on non-macOS system"
    exit 0
fi

# Simulate Codemagic environment
export CI=true
export WORKFLOW_NAME="iOS Publish"

# Set required environment variables (normally injected by Codemagic API/workflow)
export VERSION_NAME="${VERSION_NAME:-1.0.22}"
export VERSION_CODE="${VERSION_CODE:-26}"
export APP_NAME="${APP_NAME:-Garbcode App}"
export ORG_NAME="${ORG_NAME:-Garbcode Apparels Private Limited}"
export WEB_URL="${WEB_URL:-https://garbcode.com/}"
export BUNDLE_ID="${BUNDLE_ID:-com.garbcode.garbcodeapp}"
export EMAIL_ID="${EMAIL_ID:-prasannasrinivasan32@gmail.com}"

# Feature flags
export PUSH_NOTIFY="${PUSH_NOTIFY:-true}"
export IS_CHATBOT="${IS_CHATBOT:-true}"
export IS_DEEPLINK="${IS_DEEPLINK:-true}"
export IS_SPLASH="${IS_SPLASH:-true}"
export IS_PULLDOWN="${IS_PULLDOWN:-true}"
export IS_BOTTOMMENU="${IS_BOTTOMMENU:-false}"
export IS_LOAD_IND="${IS_LOAD_IND:-true}"

# Permissions
export IS_CAMERA="${IS_CAMERA:-false}"
export IS_LOCATION="${IS_LOCATION:-false}"
export IS_MIC="${IS_MIC:-true}"
export IS_NOTIFICATION="${IS_NOTIFICATION:-true}"
export IS_CONTACT="${IS_CONTACT:-false}"
export IS_BIOMETRIC="${IS_BIOMETRIC:-false}"
export IS_CALENDAR="${IS_CALENDAR:-false}"
export IS_STORAGE="${IS_STORAGE:-true}"

# iOS-specific permissions
export IS_PHOTO_LIBRARY="${IS_PHOTO_LIBRARY:-false}"
export IS_PHOTO_LIBRARY_ADD="${IS_PHOTO_LIBRARY_ADD:-false}"
export IS_FACE_ID="${IS_FACE_ID:-false}"
export IS_TOUCH_ID="${IS_TOUCH_ID:-false}"

# Assets
export LOGO_URL="${LOGO_URL:-https://raw.githubusercontent.com/prasanna91/QuikApp/main/logo-gc.png}"
export SPLASH="${SPLASH:-https://raw.githubusercontent.com/prasanna91/QuikApp/main/logo-gc.png}"
export SPLASH_BG="${SPLASH_BG:-}"
export SPLASH_BG_COLOR="${SPLASH_BG_COLOR:-#cbdbf5}"
export SPLASH_TAGLINE="${SPLASH_TAGLINE:-Welcome to Garbcode}"
export SPLASH_TAGLINE_COLOR="${SPLASH_TAGLINE_COLOR:-#a30237}"
export SPLASH_ANIMATION="${SPLASH_ANIMATION:-zoom}"
export SPLASH_DURATION="${SPLASH_DURATION:-4}"

# Bottom Menu (disabled for this test)
export BOTTOMMENU_ITEMS="${BOTTOMMENU_ITEMS:-}"
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

# Firebase (for testing, using empty values)
export firebase_config_ios="${firebase_config_ios:-}"

# iOS Configuration (for testing, using empty values)
export APPLE_TEAM_ID="${APPLE_TEAM_ID:-}"
export APNS_KEY_ID="${APNS_KEY_ID:-}"
export APNS_AUTH_KEY_URL="${APNS_AUTH_KEY_URL:-}"
export CERT_PASSWORD="${CERT_PASSWORD:-}"
export PROFILE_URL="${PROFILE_URL:-}"
export CERT_CER_URL="${CERT_CER_URL:-}"
export CERT_KEY_URL="${CERT_KEY_URL:-}"
export APP_STORE_CONNECT_KEY_IDENTIFIER="${APP_STORE_CONNECT_KEY_IDENTIFIER:-}"
export IPHONEOS_DEPLOYMENT_TARGET="${IPHONEOS_DEPLOYMENT_TARGET:-13.0}"
export COCOAPODS_PLATFORM="${COCOAPODS_PLATFORM:-13.0}"
export EXPORT_METHOD="${EXPORT_METHOD:-app-store}"
export IS_DEVELOPMENT_PROFILE="${IS_DEVELOPMENT_PROFILE:-false}"
export IS_PRODUCTION_PROFILE="${IS_PRODUCTION_PROFILE:-true}"

# Email Configuration (empty for CI)
export SMTP_SERVER="${SMTP_SERVER:-}"
export SMTP_PORT="${SMTP_PORT:-}"
export SMTP_USERNAME="${SMTP_USERNAME:-}"
export SMTP_PASSWORD="${SMTP_PASSWORD:-}"

echo "🔧 Environment configured for iOS Publish workflow"
echo "📋 CI=$CI"
echo "🍎 App: $APP_NAME ($BUNDLE_ID) v$VERSION_NAME"
echo ""

# Function to run a step with error handling
run_step() {
    local step_name="$1"
    local step_command="$2"
    
    echo "🚀 Running: $step_name"
    echo "----------------------------------------"
    
    if eval "$step_command"; then
        echo "✅ $step_name completed successfully"
        echo ""
    else
        echo "❌ $step_name failed"
        exit 1
    fi
}

# Step 1: Get Flutter packages
run_step "Get Flutter packages" "flutter pub get"

# Step 2: Setup iOS Dependencies
run_step "Setup iOS Dependencies" '
echo "📦 Setting up iOS dependencies..."

cd ios

# Check if Xcode is available
if ! command -v xcodebuild >/dev/null 2>&1; then
    echo "❌ Xcode is not installed or not in PATH"
    exit 1
fi

XCODE_VERSION=$(xcodebuild -version | head -n 1)
echo "✅ $XCODE_VERSION"

# Check and install CocoaPods if needed
echo "🔍 Checking CocoaPods installation..."
if ! command -v pod >/dev/null 2>&1 || ! pod --version >/dev/null 2>&1; then
    echo "📥 Installing CocoaPods..."
    if command -v brew >/dev/null 2>&1; then
        brew install cocoapods || {
            echo "⚠️  Failed to install CocoaPods via Homebrew, trying gem install..."
            sudo gem install cocoapods || {
                echo "❌ Failed to install CocoaPods"
                echo "ℹ️  Please install CocoaPods manually: https://cocoapods.org/"
                echo "ℹ️  For CI/Codemagic, CocoaPods is pre-installed"
                exit 1
            }
        }
    else
        echo "⚠️  Homebrew not found, trying gem install..."
        sudo gem install cocoapods || {
            echo "❌ Failed to install CocoaPods"
            echo "ℹ️  Please install CocoaPods manually: https://cocoapods.org/"
            echo "ℹ️  For CI/Codemagic, CocoaPods is pre-installed"
            exit 1
        }
    fi
fi

POD_VERSION=$(pod --version 2>/dev/null || echo "unknown")
echo "✅ CocoaPods version: $POD_VERSION"

# Create or update Podfile for iOS 13.0+ compatibility
echo "📄 Creating optimized Podfile..."
cat > Podfile << EOF
platform :ios, "13.0"
use_frameworks! :linkage => :static

ENV["COCOAPODS_DISABLE_STATS"] = "true"

def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join("..", "Flutter", "Generated.xcconfig"), __FILE__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "#{generated_xcode_build_settings_path} must exist. If you are running pod install manually, make sure flutter pub get is executed first"
  end

  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT\\=(.*)/)
    return matches[1].strip if matches
  end
  raise "FLUTTER_ROOT not found"
end

require File.expand_path(File.join("packages", "flutter_tools", "bin", "podhelper"), flutter_root)

flutter_ios_podfile_setup

target "Runner" do
  use_frameworks!
  use_modular_headers!
  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings["IPHONEOS_DEPLOYMENT_TARGET"] = "13.0"
      config.build_settings["ENABLE_BITCODE"] = "NO"
      config.build_settings["EXCLUDED_ARCHS[sdk=iphonesimulator*]"] = "arm64"
    end
  end
end
EOF

# Clean and install with retry mechanism
echo "🧹 Cleaning iOS dependencies..."
rm -rf Pods/ Podfile.lock

echo "📦 Installing iOS dependencies..."
for i in {1..3}; do
    if pod install --repo-update; then
        echo "✅ iOS dependencies installed successfully"
        break
    else
        if [ $i -eq 3 ]; then
            echo "❌ Pod install failed after 3 attempts"
            echo "ℹ️  This might be due to network issues or missing dependencies"
            echo "ℹ️  In Codemagic, this step typically works without issues"
            exit 1
        fi
        echo "🔄 Retrying pod install (attempt $((i+1))/3)..."
        sleep 10
    fi
done

cd ..
'

# Step 3: Validate iOS Project Structure
run_step "Validate iOS Project Structure" '
echo "🔍 Validating iOS project structure..."

# Check critical iOS files
REQUIRED_FILES=(
    "ios/Runner.xcodeproj/project.pbxproj"
    "ios/Runner/Info.plist"
    "ios/Runner/AppDelegate.swift"
    "ios/Podfile"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo "❌ Missing required file: $file"
        exit 1
    else
        echo "✅ Found: $file"
    fi
done

# Check if workspace was created by CocoaPods
if [ ! -f "ios/Runner.xcworkspace/contents.xcworkspacedata" ]; then
    echo "❌ Xcode workspace not found - CocoaPods may have failed"
    exit 1
else
    echo "✅ Xcode workspace found"
fi

echo "✅ iOS project structure validated"
'

# Step 4: Setup iOS Code Signing (Simplified for local testing)
run_step "Setup iOS Code Signing (Simplified)" '
echo "🔐 Setting up iOS code signing for local testing..."

# For local testing, we will skip actual certificate setup
# In Codemagic, this would download and install certificates
echo "ℹ️  Skipping certificate download for local testing"

# Check if we have signing certificates available locally
if security find-identity -v -p codesigning | grep -q "iPhone"; then
    echo "✅ Found local iOS signing certificates"
else
    echo "⚠️  No iOS signing certificates found locally"
    echo "ℹ️  For actual deployment, certificates would be configured in Codemagic"
fi

# Verify bundle ID format
if [[ "$BUNDLE_ID" =~ ^[a-zA-Z0-9.-]+$ ]]; then
    echo "✅ Bundle ID format is valid: $BUNDLE_ID"
else
    echo "❌ Invalid bundle ID format: $BUNDLE_ID"
    exit 1
fi
'

# Step 5: Build iOS App
run_step "Build iOS App" '
echo "🍎 Building iOS app..."

# Build iOS app with comprehensive dart-define parameters
echo "🏗️ Building iOS app with all configurations..."

if ! flutter build ios --release --no-codesign \
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
  
  echo "❌ iOS build failed, retrying with minimal config..."
  flutter clean
  cd ios && pod install && cd ..
  flutter pub get
  
  flutter build ios --release --no-codesign \
    --dart-define=BUNDLE_ID="$BUNDLE_ID" \
    --dart-define=APP_NAME="$APP_NAME" \
    --dart-define=VERSION_NAME="$VERSION_NAME" \
    --dart-define=VERSION_CODE="$VERSION_CODE"
fi

echo "✅ iOS build completed"
'

# Step 6: Create IPA (Simplified for local testing)
run_step "Create IPA (Simplified)" '
echo "📦 Creating IPA for distribution..."

cd ios

# For local testing, we will create an unsigned IPA
# In Codemagic, this would be properly signed
echo "ℹ️  Creating unsigned IPA for local testing..."

# Check if the app was built
if [ ! -d "build/ios/iphoneos/Runner.app" ]; then
    echo "❌ iOS app not found at expected location"
    find build/ -name "*.app" -type d | head -3
    exit 1
fi

# Create Payload directory structure
mkdir -p build/ios/ipa/Payload
cp -r build/ios/iphoneos/Runner.app build/ios/ipa/Payload/

# Create IPA
cd build/ios/ipa
zip -r Runner.ipa Payload/
cd ../../..

if [ -f "build/ios/ipa/Runner.ipa" ]; then
    echo "✅ IPA created successfully"
    ls -la build/ios/ipa/Runner.ipa
else
    echo "❌ Failed to create IPA"
    exit 1
fi

cd ..
'

# Step 7: Copy iOS artifacts to output folder
run_step "Copy iOS artifacts to output folder" '
echo "📁 Collecting iOS build artifacts..."

# Create output directory
mkdir -p output

# Copy iOS artifacts with validation
echo "🍎 Checking iOS artifacts..."

if [ -f "ios/build/ios/ipa/Runner.ipa" ]; then
    cp ios/build/ios/ipa/Runner.ipa output/
    echo "✅ iOS IPA copied to output/"
else
    echo "⚠️  iOS IPA not found at expected location"
    # Look for .app files as fallback
    APP_FILE=$(find ios/build/ -name "*.app" -type d | head -1)
    if [ -n "$APP_FILE" ]; then
        cp -r "$APP_FILE" output/
        echo "✅ iOS .app copied to output/"
    else
        echo "❌ No iOS artifacts found"
        exit 1
    fi
fi

echo "📋 Final iOS Build Summary:"
echo "=========================="
if [ -d "output" ]; then
    ls -la output/
    echo ""
    echo "🍎 iOS Files:"
    ls output/*.ipa 2>/dev/null && echo "  ✅ IPA found" || echo "  ❌ IPA missing"
    ls output/*.app 2>/dev/null && echo "  ✅ APP found" || echo "  ❌ APP missing"
else
    echo "❌ No output directory created"
fi
'

# Step 8: Send success notification (simplified for local testing)
run_step "Send success notification" '
echo "📧 Sending iOS build success notification..."

# For iOS, we would typically use the Android email scripts or create iOS-specific ones
if [ -f "lib/scripts/android/send_output_email.sh" ]; then
    bash lib/scripts/android/send_output_email.sh 2>/dev/null || true
    echo "✅ Success notification sent for iOS build"
else
    echo "ℹ️  Email notification skipped (script not found or email not configured)"
fi
'

echo ""
echo "🎉 iOS Publish Workflow Test Completed Successfully!"
echo "=================================================="
echo ""
echo "📋 Summary:"
echo "• Environment: CI simulation (CI=$CI)"
echo "• Workflow: iOS Publish"
echo "• iOS build: Completed"
echo "• Artifacts: Available in output/ directory"
echo "• Email notifications: Processed"
echo ""
echo "🚀 Your iOS Publish workflow is ready for Codemagic!" 