#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Function to handle errors
handle_error() {
    local error_msg="$1"
    echo "❌ Error: $error_msg"
    bash "$(dirname "$0")/send_error_email.sh" "iOS Build Failed" "$error_msg"
    exit 1
}

# Function to setup iOS Firebase
setup_firebase() {
    echo "🔥 Setting up iOS Firebase..."
    
    if [ "$PUSH_NOTIFY" = "true" ] && [ -n "$FIREBASE_CONFIG_IOS" ]; then
        # Download GoogleService-Info.plist
        wget -O ios/Runner/GoogleService-Info.plist "$FIREBASE_CONFIG_IOS" || handle_error "Failed to download Firebase config"
    fi
    
    echo "✅ Firebase setup complete"
}

# Function to setup Podfile
setup_podfile() {
    echo "📝 Setting up Podfile..."
    
    cd ios
    
    # Create Podfile if not exists
    if [ ! -f "Podfile" ]; then
        cat > Podfile << EOF
platform :ios, '$IPHONEOS_DEPLOYMENT_TARGET'
use_frameworks!

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
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '$IPHONEOS_DEPLOYMENT_TARGET'
    end
  end
end
EOF
    fi
    
    # Install pods
    pod install || handle_error "Failed to install iOS pods"
    
    cd ..
    echo "✅ Podfile setup complete"
}

# Function to build iOS app
build_ios() {
    echo "🏗️ Building iOS app..."
    
    flutter build ios --release --no-codesign \
        --dart-define=BUNDLE_ID="$BUNDLE_ID" \
        --dart-define=APP_NAME="$APP_NAME" \
        --dart-define=VERSION_NAME="$VERSION_NAME" \
        --dart-define=VERSION_CODE="$VERSION_CODE" \
        --dart-define=PUSH_NOTIFY="$PUSH_NOTIFY" \
        --dart-define=WEB_URL="$WEB_URL" || handle_error "Failed to build iOS app"
    
    echo "✅ iOS build complete"
}

# Function to create IPA
create_ipa() {
    echo "📦 Creating IPA..."
    
    cd ios
    
    # Create IPA directory
    mkdir -p build/ios/ipa/Payload
    
    # Copy app to Payload
    if [ -d "../build/ios/iphoneos/Runner.app" ]; then
        cp -r ../build/ios/iphoneos/Runner.app build/ios/ipa/Payload/
        
        # Create IPA
        cd build/ios/ipa
        zip -r Runner.ipa Payload/
        cd ../../..
        
        echo "✅ IPA created successfully"
    else
        handle_error "Runner.app not found"
    fi
    
    cd ..
}

# Function to collect iOS artifacts
collect_artifacts() {
    echo "📦 Collecting iOS artifacts..."
    
    # Create output directory
    mkdir -p output
    
    # Copy IPA
    if [ -f "ios/build/ios/ipa/Runner.ipa" ]; then
        cp ios/build/ios/ipa/Runner.ipa output/
        echo "✅ IPA copied to output/"
    fi
    
    echo "✅ iOS artifacts collected"
}

# Main iOS build process
echo "🚀 Starting iOS build process..."

setup_firebase
setup_podfile
build_ios
create_ipa
collect_artifacts

echo "✅ iOS build process completed successfully" 