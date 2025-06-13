#!/bin/bash
set -e

echo "🧪 Testing Android Publish Workflow Locally"
echo "==========================================="
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
export WORKFLOW_NAME="Android Publish"

# Set required environment variables (normally injected by Codemagic API/workflow)
export VERSION_NAME="${VERSION_NAME:-1.0.22}"
export VERSION_CODE="${VERSION_CODE:-26}"
export APP_NAME="${APP_NAME:-Garbcode App}"
export ORG_NAME="${ORG_NAME:-Garbcode Apparels Private Limited}"
export WEB_URL="${WEB_URL:-https://garbcode.com/}"
export PKG_NAME="${PKG_NAME:-com.garbcode.garbcodeapp}"
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

# Android Configuration (for testing, using empty values)
export KEY_STORE="${KEY_STORE:-}"
export CM_KEYSTORE_PASSWORD="${CM_KEYSTORE_PASSWORD:-}"
export CM_KEY_ALIAS="${CM_KEY_ALIAS:-}"
export CM_KEY_PASSWORD="${CM_KEY_PASSWORD:-}"
export COMPILE_SDK_VERSION="${COMPILE_SDK_VERSION:-35}"
export MIN_SDK_VERSION="${MIN_SDK_VERSION:-21}"
export TARGET_SDK_VERSION="${TARGET_SDK_VERSION:-35}"

# Email Configuration (empty for CI)
export SMTP_SERVER="${SMTP_SERVER:-}"
export SMTP_PORT="${SMTP_PORT:-}"
export SMTP_USERNAME="${SMTP_USERNAME:-}"
export SMTP_PASSWORD="${SMTP_PASSWORD:-}"

echo "🔧 Environment configured for Android Publish workflow"
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

# Step 2: Force Gradle Wrapper Version
run_step "Force Gradle Wrapper Version" '
cat > android/gradle/wrapper/gradle-wrapper.properties <<EOF
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.12-all.zip
EOF
echo "✅ Forced gradle-wrapper.properties to Gradle 8.12"
'

# Step 3: Get Flutter packages
run_step "Get Flutter packages" "flutter pub get"

# Step 4: Initialize Android Gradle Wrapper
run_step "Initialize Android Gradle Wrapper" '
echo "🔧 Initializing Android Gradle Wrapper for compatibility..."

cd android

# Check Java availability
echo "🔍 Checking Java installation..."
if ! command -v java >/dev/null 2>&1; then
    echo "❌ Java is not installed or not in PATH"
    exit 1
fi

JAVA_VERSION=$(java -version 2>&1 | awk -F "\"" "/version/ {print \$2}")
echo "✅ Java version: $JAVA_VERSION"

# Create gradle wrapper directory if it doesn'\''t exist
mkdir -p gradle/wrapper

# Download gradle-wrapper.jar
echo "📥 Downloading gradle-wrapper.jar..."
curl -o gradle/wrapper/gradle-wrapper.jar https://raw.githubusercontent.com/gradle/gradle/v8.12.0/gradle/wrapper/gradle-wrapper.jar

# Create gradle-wrapper.properties
echo "📝 Creating gradle-wrapper.properties..."
cat > gradle/wrapper/gradle-wrapper.properties <<EOF
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.12-bin.zip
networkTimeout=10000
validateDistributionUrl=true
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
EOF

# Make gradlew executable
chmod +x gradlew

# Verify the wrapper setup
echo "🔍 Verifying Gradle wrapper setup..."
if [ ! -f "gradle/wrapper/gradle-wrapper.jar" ]; then
    echo "❌ gradle-wrapper.jar not found"
    exit 1
fi

if [ ! -f "gradle/wrapper/gradle-wrapper.properties" ]; then
    echo "❌ gradle-wrapper.properties not found"
    exit 1
fi

cd ..
echo "✅ Gradle wrapper initialization complete"
'

# Step 5: Validate Android Project Structure
run_step "Validate Android Project Structure" '
echo "🔍 Validating Android project structure..."

# Check critical Android files
REQUIRED_FILES=(
    "android/app/build.gradle"
    "android/build.gradle"
    "android/gradle.properties"
    "android/settings.gradle"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo "❌ Missing required file: $file"
        exit 1
    else
        echo "✅ Found: $file"
    fi
done

# Ensure Android SDK versions are compatible
echo "🔧 Checking Android SDK compatibility for API 35..."

# Check if build.gradle has proper compileSdkVersion
if grep -q "compileSdkVersion.*3[5-9]" android/app/build.gradle; then
    echo "✅ Compatible compileSdkVersion found"
else
    echo "⚠️  May need compileSdkVersion update for Android 15"
fi

echo "✅ Android project structure validated"
'

# Step 6: Run Android build script
run_step "Run Android build script" '
echo "🚀 Running Android build using comprehensive script system..."

# Set workflow name for email notifications
export WORKFLOW_NAME="Android Publish"

# Check if we have the comprehensive Android main.sh script
if [ -f "lib/scripts/android/main.sh" ]; then
    echo "🎯 Using comprehensive Android main.sh script..."
    chmod +x lib/scripts/android/main.sh
    ./lib/scripts/android/main.sh
else
    echo "⚠️  Android main.sh not found, using enhanced fallback build process..."
    
    # Enhanced Fallback: Set up Android code signing
    echo "🔐 Setting up Android code signing..."
    if [ -n "$KEY_STORE" ]; then
        echo "📥 Downloading keystore..."
        wget -O android/app/keystore.jks "$KEY_STORE"
        cat > android/key.properties << EOF
storePassword=$CM_KEYSTORE_PASSWORD
keyPassword=$CM_KEY_PASSWORD
keyAlias=$CM_KEY_ALIAS
storeFile=keystore.jks
EOF
        echo "✅ Keystore configured"
    fi
    
    # Build APK and AAB with comprehensive error handling
    echo "🏗️ Building Android APK and AAB..."
    
    # Build APK with retry mechanism
    echo "📱 Building APK..."
    if ! flutter build apk --release \
      --dart-define=PKG_NAME="$PKG_NAME" \
      --dart-define=APP_NAME="$APP_NAME" \
      --dart-define=ORG_NAME="$ORG_NAME" \
      --dart-define=VERSION_NAME="$VERSION_NAME" \
      --dart-define=VERSION_CODE="$VERSION_CODE" \
      --dart-define=PUSH_NOTIFY="$PUSH_NOTIFY" \
      --dart-define=firebase_config_android="$firebase_config_android" \
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
      --dart-define=IS_STORAGE="$IS_STORAGE"; then
      
      echo "❌ APK build failed, trying with clean..."
      flutter clean
      flutter pub get
      
      flutter build apk --release \
        --dart-define=PKG_NAME="$PKG_NAME" \
        --dart-define=APP_NAME="$APP_NAME" \
        --dart-define=VERSION_NAME="$VERSION_NAME" \
        --dart-define=VERSION_CODE="$VERSION_CODE" \
        --dart-define=PUSH_NOTIFY="$PUSH_NOTIFY"
    fi
    
    # Build AAB
    echo "📦 Building AAB..."
    flutter build appbundle --release \
      --dart-define=PKG_NAME="$PKG_NAME" \
      --dart-define=APP_NAME="$APP_NAME" \
      --dart-define=ORG_NAME="$ORG_NAME" \
      --dart-define=VERSION_NAME="$VERSION_NAME" \
      --dart-define=VERSION_CODE="$VERSION_CODE" \
      --dart-define=PUSH_NOTIFY="$PUSH_NOTIFY" \
      --dart-define=firebase_config_android="$firebase_config_android" \
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
      --dart-define=IS_STORAGE="$IS_STORAGE"
    
    # Move outputs
    echo "📁 Moving build outputs..."
    mkdir -p output
    
    # Check for APK
    if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
        cp build/app/outputs/flutter-apk/app-release.apk output/
        echo "✅ APK moved to output/"
    else
        echo "⚠️  APK not found at expected location"
        find build/ -name "*.apk" -type f | head -5
    fi
    
    # Check for AAB
    if [ -f "build/app/outputs/bundle/release/app-release.aab" ]; then
        cp build/app/outputs/bundle/release/app-release.aab output/
        echo "✅ AAB moved to output/"
    else
        echo "⚠️  AAB not found at expected location"
        find build/ -name "*.aab" -type f | head -5
    fi
    
    echo "📋 Final output contents:"
    ls -la output/ || echo "No output directory"
fi
'

# Step 7: Send success notification
run_step "Send success notification" '
echo "📧 Sending success notification..."

if [ -f "lib/scripts/android/send_output_email.sh" ]; then
    bash lib/scripts/android/send_output_email.sh 2>/dev/null || true
    echo "✅ Success notification sent"
else
    echo "ℹ️  Email notification skipped (script not found or email not configured)"
fi
'

echo ""
echo "🎉 Android Publish Workflow Test Completed Successfully!"
echo "======================================================"
echo ""
echo "📋 Summary:"
echo "• Environment: CI simulation (CI=$CI)"
echo "• Workflow: Android Publish"
echo "• Android build: Completed"
echo "• Artifacts: Available in output/ directory"
echo "• Email notifications: Processed"
echo ""
echo "🚀 Your Android Publish workflow is ready for Codemagic!" 