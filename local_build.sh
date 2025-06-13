#!/usr/bin/env bash
set -e

echo "🚀 Starting Combined Android & iOS Build..."

# Function to print section headers
print_section() {
    echo ""
    echo "=== $1 ==="
    echo ""
}

# Function to check command status
check_status() {
    if [ $? -eq 0 ]; then
        echo "✅ $1"
    else
        echo "❌ $1"
        exit 1
    fi
}

# Initialize Build Environment
print_section "Initializing Build Environment"

# Check Java installation
echo "🔍 Checking Java installation..."
if ! command -v java >/dev/null 2>&1; then
    echo "❌ Java is not installed or not in PATH"
    exit 1
fi

JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
echo "✅ Java version: $JAVA_VERSION"

# Create Gradle wrapper directory if it doesn't exist
echo "📁 Creating Gradle wrapper directory..."
mkdir -p android/gradle/wrapper
check_status "Created Gradle wrapper directory"

# Download Gradle wrapper JAR
echo "📥 Downloading Gradle wrapper JAR..."
curl -L -o android/gradle/wrapper/gradle-wrapper.jar https://raw.githubusercontent.com/gradle/gradle/v8.12.0/gradle/wrapper/gradle-wrapper.jar
check_status "Downloaded Gradle wrapper JAR"

# Verify JAR file exists and has content
if [ ! -s "android/gradle/wrapper/gradle-wrapper.jar" ]; then
    echo "❌ Gradle wrapper JAR is empty or missing"
    exit 1
fi
echo "✅ Verified Gradle wrapper JAR"

# Create gradle-wrapper.properties
echo "📝 Creating gradle-wrapper.properties..."
cat > android/gradle/wrapper/gradle-wrapper.properties <<EOF
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.12-all.zip
EOF
check_status "Created gradle-wrapper.properties"

# Create gradlew script with absolute path
echo "📝 Creating gradlew script..."
cat > android/gradlew <<EOF
#!/usr/bin/env sh

# Find the directory where this script is located
SCRIPT_DIR="\$( cd "\$( dirname "\$0" )" && pwd )"
WRAPPER_JAR="\${SCRIPT_DIR}/gradle/wrapper/gradle-wrapper.jar"

# Verify the wrapper JAR exists
if [ ! -f "\${WRAPPER_JAR}" ]; then
    echo "Error: Could not find gradle-wrapper.jar at \${WRAPPER_JAR}"
    exit 1
fi

# Execute Gradle with the wrapper JAR
exec java -cp "\${WRAPPER_JAR}" org.gradle.wrapper.GradleWrapperMain "\$@"
EOF

chmod +x android/gradlew
check_status "Created gradlew script"

# Verify the gradlew script
echo "🔍 Verifying gradlew script..."
if [ ! -x "android/gradlew" ]; then
    echo "❌ gradlew script is not executable"
    exit 1
fi
echo "✅ Verified gradlew script"

# Clean Gradle cache and stop daemons
echo "🧹 Cleaning Gradle cache and stopping daemons..."
cd android
./gradlew --stop || true
cd ..
check_status "Cleaned Gradle cache"

# Verify Gradle version
echo "🔍 Verifying Gradle version..."
cd android
./gradlew --version
cd ..
check_status "Verified Gradle version"

# Get Flutter packages
print_section "Getting Flutter Packages"
flutter pub get
check_status "Got Flutter packages"

# Build Android
print_section "Building Android"
echo "🏗️ Building Android APK and AAB..."

# Build APK
flutter build apk --release \
    --dart-define=PKG_NAME="$PKG_NAME" \
    --dart-define=APP_NAME="$APP_NAME" \
    --dart-define=VERSION_NAME="$VERSION_NAME" \
    --dart-define=VERSION_CODE="$VERSION_CODE" \
    --dart-define=PUSH_NOTIFY="$PUSH_NOTIFY" \
    --dart-define=WEB_URL="$WEB_URL" \
    --dart-define=IS_SPLASH="$IS_SPLASH" \
    --dart-define=SPLASH="$SPLASH" \
    --dart-define=IS_BOTTOMMENU="$IS_BOTTOMMENU" \
    --dart-define=BOTTOMMENU_ITEMS="$BOTTOMMENU_ITEMS"
check_status "Built Android APK"

# Build AAB
flutter build appbundle --release \
    --dart-define=PKG_NAME="$PKG_NAME" \
    --dart-define=APP_NAME="$APP_NAME" \
    --dart-define=VERSION_NAME="$VERSION_NAME" \
    --dart-define=VERSION_CODE="$VERSION_CODE" \
    --dart-define=PUSH_NOTIFY="$PUSH_NOTIFY" \
    --dart-define=WEB_URL="$WEB_URL" \
    --dart-define=IS_SPLASH="$IS_SPLASH" \
    --dart-define=SPLASH="$SPLASH" \
    --dart-define=IS_BOTTOMMENU="$IS_BOTTOMMENU" \
    --dart-define=BOTTOMMENU_ITEMS="$BOTTOMMENU_ITEMS"
check_status "Built Android AAB"

# Setup iOS Dependencies
print_section "Setting up iOS Dependencies"

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "⚠️  Skipping iOS build - not running on macOS"
else
    cd ios

    # Create or update Podfile
    if [ ! -f "Podfile" ]; then
        echo "📄 Creating Podfile..."
        cat > Podfile <<EOF
platform :ios, '13.0'
use_frameworks! :linkage => :static

ENV['COCOAPODS_DISABLE_STATS'] = 'true'

def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'Generated.xcconfig'), __FILE__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "#{generated_xcode_build_settings_path} must exist. If you're running pod install manually, make sure flutter pub get is executed first"
  end

  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT\\=(.*)/)
    return matches[1].strip if matches
  end
  raise "FLUTTER_ROOT not found"
end

require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)

flutter_ios_podfile_setup

target 'Runner' do
  use_frameworks!
  use_modular_headers!
  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      config.build_settings['ENABLE_BITCODE'] = 'NO'
    end
  end
end
EOF
    fi

    # Install pods
    echo "📦 Installing CocoaPods dependencies..."
    pod install --repo-update
    check_status "Installed CocoaPods dependencies"

    cd ..

    # Build iOS
    print_section "Building iOS"
    flutter build ios --release --no-codesign \
        --dart-define=BUNDLE_ID="$BUNDLE_ID" \
        --dart-define=APP_NAME="$APP_NAME" \
        --dart-define=VERSION_NAME="$VERSION_NAME" \
        --dart-define=VERSION_CODE="$VERSION_CODE" \
        --dart-define=PUSH_NOTIFY="$PUSH_NOTIFY" \
        --dart-define=WEB_URL="$WEB_URL" \
        --dart-define=IS_SPLASH="$IS_SPLASH" \
        --dart-define=SPLASH="$SPLASH" \
        --dart-define=IS_BOTTOMMENU="$IS_BOTTOMMENU" \
        --dart-define=BOTTOMMENU_ITEMS="$BOTTOMMENU_ITEMS"
    check_status "Built iOS app"
fi

# Copy artifacts to output folder
print_section "Collecting Build Artifacts"
mkdir -p output

# Copy Android artifacts
if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
    cp build/app/outputs/flutter-apk/app-release.apk output/
    echo "✅ Android APK copied to output/"
fi

if [ -f "build/app/outputs/bundle/release/app-release.aab" ]; then
    cp build/app/outputs/bundle/release/app-release.aab output/
    echo "✅ Android AAB copied to output/"
fi

# Copy iOS artifacts (if on macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    if [ -f "build/ios/ipa/Runner.ipa" ]; then
        cp build/ios/ipa/Runner.ipa output/
        echo "✅ iOS IPA copied to output/"
    else
        echo "⚠️  iOS IPA not found, checking for .app files..."
        APP_FILE=$(find build/ -name "*.app" -type d | head -1)
        if [ -n "$APP_FILE" ]; then
            cp -r "$APP_FILE" output/
            echo "✅ iOS .app copied to output/"
        fi
    fi
fi

# Print final summary
print_section "Build Summary"
echo "📋 Output directory contents:"
ls -la output/

echo ""
echo "🎉 Build process completed!" 