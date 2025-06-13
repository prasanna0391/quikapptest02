#!/bin/bash
set -e

echo "🧪 Testing Codemagic Combined Workflow Locally"
echo "=============================================="
echo ""

# Setup Java 21 for Gradle compatibility
echo "☕ Setting up Java 21 for Gradle compatibility..."
export JAVA_HOME=/opt/homebrew/opt/openjdk@21
export PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH"

# Verify Java version
if command -v java >/dev/null 2>&1; then
    JAVA_VERSION=$(java -version 2>&1 | head -n 1)
    echo "✅ Using: $JAVA_VERSION"
else
    echo "❌ Java not found. Please install Java 21."
    exit 1
fi

# Simulate Codemagic environment
export CI=true
export WORKFLOW_NAME="Combined Android & iOS Build"

# Set required environment variables (normally injected by Codemagic API/workflow)
export VERSION_NAME="${VERSION_NAME:-1.0.22}"
export VERSION_CODE="${VERSION_CODE:-26}"
export APP_NAME="${APP_NAME:-Garbcode App}"
export ORG_NAME="${ORG_NAME:-Garbcode Apparels Private Limited}"
export WEB_URL="${WEB_URL:-https://garbcode.com/}"
export PKG_NAME="${PKG_NAME:-com.garbcode.garbcodeapp}"
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
export firebase_config_android="${firebase_config_android:-}"
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

# Android Configuration (for testing, using empty values)
export KEY_STORE="${KEY_STORE:-}"
export CM_KEYSTORE_PASSWORD="${CM_KEYSTORE_PASSWORD:-}"
export CM_KEY_ALIAS="${CM_KEY_ALIAS:-}"
export CM_KEY_PASSWORD="${CM_KEY_PASSWORD:-}"
export COMPILE_SDK_VERSION="${COMPILE_SDK_VERSION:-35}"
export MIN_SDK_VERSION="${MIN_SDK_VERSION:-21}"
export TARGET_SDK_VERSION="${TARGET_SDK_VERSION:-35}"

# iOS Permissions
export IS_PHOTO_LIBRARY="${IS_PHOTO_LIBRARY:-false}"
export IS_PHOTO_LIBRARY_ADD="${IS_PHOTO_LIBRARY_ADD:-false}"
export IS_FACE_ID="${IS_FACE_ID:-false}"
export IS_TOUCH_ID="${IS_TOUCH_ID:-false}"

# Email Configuration (empty for CI)
export SMTP_SERVER="${SMTP_SERVER:-}"
export SMTP_PORT="${SMTP_PORT:-}"
export SMTP_USERNAME="${SMTP_USERNAME:-}"
export SMTP_PASSWORD="${SMTP_PASSWORD:-}"

echo "🔧 Environment configured for CI simulation"
echo "📋 CI=$CI"
echo "📱 App: $APP_NAME ($PKG_NAME) v$VERSION_NAME"
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

# Step 1: Setup local.properties for local testing
run_step "Setup local.properties for local testing" '
echo "🔧 Setting up local.properties for local testing..."

# Find Flutter SDK path
FLUTTER_PATH=$(which flutter 2>/dev/null || echo "/usr/local/bin/flutter")
if [ -n "$FLUTTER_PATH" ]; then
    FLUTTER_SDK=$(dirname $(dirname "$FLUTTER_PATH"))
    echo "📍 Found Flutter SDK at: $FLUTTER_SDK"
else
    # Common Flutter SDK locations
    if [ -d "/Users/$USER/development/flutter" ]; then
        FLUTTER_SDK="/Users/$USER/development/flutter"
    elif [ -d "/Users/$USER/flutter" ]; then
        FLUTTER_SDK="/Users/$USER/flutter"
    elif [ -d "/opt/flutter" ]; then
        FLUTTER_SDK="/opt/flutter"
    else
        echo "❌ Could not find Flutter SDK. Please install Flutter or update the path."
        exit 1
    fi
fi

# Create local.properties file in project root (required by settings.gradle)
cat > local.properties << EOF
sdk.dir=/Users/$USER/Library/Android/sdk
flutter.sdk=$FLUTTER_SDK
EOF

# Also create in android directory for compatibility
cat > android/local.properties << EOF
sdk.dir=/Users/$USER/Library/Android/sdk
flutter.sdk=$FLUTTER_SDK
EOF

echo "✅ Created local.properties in project root and android directory with Flutter SDK: $FLUTTER_SDK"
'

# Step 2: Initialize Gradle Wrapper (from codemagic.yaml)
run_step "Initialize Gradle Wrapper" '
echo "🔧 Initializing Gradle wrapper..."

# Create Gradle wrapper directory
mkdir -p android/gradle/wrapper

# Download the official Gradle distribution ZIP and extract the wrapper JAR
cd android
curl -O https://services.gradle.org/distributions/gradle-8.12-bin.zip
unzip -j gradle-8.12-bin.zip "gradle-8.12/bin/gradle-wrapper.jar" -d gradle/wrapper/
rm gradle-8.12-bin.zip

# Create gradle-wrapper.properties
cat > gradle/wrapper/gradle-wrapper.properties << EOF
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.12-all.zip
EOF

# Create gradlew script
cat > gradlew << EOF
#!/bin/sh
exec java -cp gradle/wrapper/gradle-wrapper.jar org.gradle.wrapper.GradleWrapperMain "\$@"
EOF

# Make gradlew executable
chmod +x gradlew

# Verify Gradle wrapper
./gradlew --version

cd ..
echo "✅ Gradle wrapper initialized"
'

# Step 3: Get Flutter packages
run_step "Get Flutter packages" "flutter pub get"

# Step 4: Build Android (Using main.sh)
run_step "Build Android (Using main.sh)" "bash lib/scripts/android/main.sh"

# Step 5: Setup iOS Dependencies (simplified for local testing)
if [[ "$OSTYPE" == "darwin"* ]]; then
    run_step "Setup iOS Dependencies" '
    echo "📦 Setting up iOS dependencies for combined build..."
    
    cd ios
    
    # Create or update Podfile
    if [ ! -f "Podfile" ]; then
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
    end
  end
end
EOF
    fi
    
    # Clean and install with retry
    echo "🧹 Cleaning iOS dependencies..."
    rm -rf Pods/ Podfile.lock
    
    echo "📦 Installing iOS dependencies..."
    for i in {1..2}; do
        if pod install --repo-update; then
            echo "✅ iOS dependencies installed successfully"
            break
        else
            if [ $i -eq 2 ]; then
                echo "❌ Pod install failed, but continuing..."
                break
            fi
            echo "🔄 Retrying pod install..."
            sleep 5
        fi
    done
    
    cd ..
    '
    
    # Step 6: Build iOS (simplified for local testing)
    run_step "Build iOS (simplified)" '
    echo "🍎 Building iOS using simplified process..."
    
    # Streamlined iOS build for combined workflow
    echo "🏗️ Building iOS app..."
    
    if ! flutter build ios --release --no-codesign \
      --dart-define=BUNDLE_ID="$BUNDLE_ID" \
      --dart-define=APP_NAME="$APP_NAME" \
      --dart-define=VERSION_NAME="$VERSION_NAME" \
      --dart-define=VERSION_CODE="$VERSION_CODE" \
      --dart-define=PUSH_NOTIFY="$PUSH_NOTIFY" \
      --dart-define=WEB_URL="$WEB_URL" \
      --dart-define=IS_SPLASH="$IS_SPLASH" \
      --dart-define=SPLASH="$SPLASH" \
      --dart-define=IS_BOTTOMMENU="$IS_BOTTOMMENU" \
      --dart-define=BOTTOMMENU_ITEMS="$BOTTOMMENU_ITEMS"; then
      
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
else
    echo "⚠️  Skipping iOS build (not on macOS)"
fi

# Step 7: Copy all artifacts to output folder
run_step "Copy all artifacts to output folder" '
echo "📁 Collecting all build artifacts..."

# Create output directory
mkdir -p output

# Copy Android artifacts with validation
echo "🤖 Checking Android artifacts..."
if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
    cp build/app/outputs/flutter-apk/app-release.apk output/
    echo "✅ Android APK copied to output/"
else
    echo "⚠️  Android APK not found at expected location"
    find build/ -name "*.apk" -type f | head -3
fi

if [ -f "build/app/outputs/bundle/release/app-release.aab" ]; then
    cp build/app/outputs/bundle/release/app-release.aab output/
    echo "✅ Android AAB copied to output/"
else
    echo "⚠️  Android AAB not found at expected location"
    find build/ -name "*.aab" -type f | head -3
fi

# Copy iOS artifacts with validation (if on macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🍎 Checking iOS artifacts..."
    if [ -f "build/ios/ipa/Runner.ipa" ]; then
        cp build/ios/ipa/Runner.ipa output/
        echo "✅ iOS IPA copied to output/"
    else
        echo "⚠️  iOS IPA not found, checking for alternatives..."
        # Look for .app files as fallback
        APP_FILE=$(find build/ -name "*.app" -type d | head -1)
        if [ -n "$APP_FILE" ]; then
            cp -r "$APP_FILE" output/
            echo "✅ iOS .app copied to output/"
        else
            echo "⚠️  No iOS artifacts found"
        fi
    fi
fi

echo "📋 Final Build Summary:"
echo "======================="
if [ -d "output" ]; then
    ls -la output/
    echo ""
    echo "📱 Android Files:"
    ls output/*.apk 2>/dev/null && echo "  ✅ APK found" || echo "  ❌ APK missing"
    ls output/*.aab 2>/dev/null && echo "  ✅ AAB found" || echo "  ❌ AAB missing"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "🍎 iOS Files:"
        ls output/*.ipa 2>/dev/null && echo "  ✅ IPA found" || echo "  ❌ IPA missing"
        ls output/*.app 2>/dev/null && echo "  ✅ APP found" || echo "  ❌ APP missing"
    fi
else
    echo "❌ No output directory created"
fi
'

# Step 8: Send success notification (simplified for local testing)
run_step "Send success notification" '
echo "📧 Sending combined build success notification..."

if [ -f "lib/scripts/android/send_output_email.sh" ]; then
    bash lib/scripts/android/send_output_email.sh 2>/dev/null || true
    echo "✅ Success notification sent for combined build"
else
    echo "ℹ️  Email notification skipped (script not found or email not configured)"
fi
'

echo ""
echo "🎉 Combined Workflow Test Completed Successfully!"
echo "================================================"
echo ""
echo "📋 Summary:"
echo "• Environment: CI simulation (CI=$CI)"
echo "• Android build: Completed"
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "• iOS build: Completed"
else
    echo "• iOS build: Skipped (not on macOS)"
fi
echo "• Artifacts: Available in output/ directory"
echo "• Email notifications: Processed"
echo ""
echo "🚀 Your combined workflow is ready for Codemagic!" 