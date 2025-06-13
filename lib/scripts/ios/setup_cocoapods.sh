#!/usr/bin/env bash

set -euo pipefail

# Add Homebrew to PATH to ensure we use the correct CocoaPods installation
export PATH="/opt/homebrew/bin:$PATH"

echo "📦 Setting up CocoaPods for iOS build..."

# Check if required environment variables are set
if [ -z "${IPHONEOS_DEPLOYMENT_TARGET:-}" ]; then
    echo "❌ Error: IPHONEOS_DEPLOYMENT_TARGET environment variable is not set"
    exit 1
fi

if [ -z "${COCOAPODS_PLATFORM:-}" ]; then
    echo "❌ Error: COCOAPODS_PLATFORM environment variable is not set"
    exit 1
fi

# Set local variables
deployment_target="$IPHONEOS_DEPLOYMENT_TARGET"
platform="$COCOAPODS_PLATFORM"
team_id="${APPLE_TEAM_ID:-9H2AD7NQ49}"
export_method="${EXPORT_METHOD:-app-store}"
is_development_profile="${IS_DEVELOPMENT_PROFILE:-false}"

echo "🧹 Deleting old CocoaPods artifacts..."
# Use find with -delete for robustness
find ios/ -name "Pods" -exec rm -rf {} + || true
find ios/ -name "Podfile.lock" -delete || true
find ios/ -name ".symlinks" -delete || true
find ios/Flutter/ -name "Flutter.podspec" -delete || true
echo "✅ Deleted old CocoaPods artifacts (if they existed)."

cd ios

# Generate Podfile with dynamic values
echo "📄 Generating Podfile with dynamic values..."
cat > Podfile <<EOF
platform :ios, '$deployment_target'
ENV['COCOAPODS_DISABLE_STATS'] = 'true'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

def flutter_root
  File.foreach(File.expand_path(File.join('..', 'Flutter', 'Generated.xcconfig'), __FILE__)) do |line|
    matches = line.match(/FLUTTER_ROOT=(.*)/)
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

  post_install do |installer|
    installer.pods_project.targets.each do |target|
      flutter_additional_ios_build_settings(target)
      target.build_configurations.each do |config|
EOF

# Add dynamic code signing configuration based on profile type and export method
if [ "$is_development_profile" = "true" ] || [ "$export_method" = "development" ]; then
    echo "🔧 Using automatic signing for development profile"
    cat >> Podfile <<EOF
        # Development profile - Automatic code signing
        config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
        config.build_settings['DEVELOPMENT_TEAM'] = '$team_id'
        config.build_settings['CODE_SIGNING_REQUIRED'] = 'YES'
        config.build_settings['CODE_SIGNING_ALLOWED'] = 'YES'
        config.build_settings.delete('CODE_SIGN_IDENTITY') # Let Xcode choose automatically
        config.build_settings.delete('PROVISIONING_PROFILE_SPECIFIER') # Let Xcode pick automatically
EOF
elif [ "$export_method" = "app-store" ]; then
    echo "🔧 Using automatic signing for App Store distribution"
    cat >> Podfile <<EOF
        # App Store distribution - Automatic code signing
        config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
        config.build_settings['DEVELOPMENT_TEAM'] = '$team_id'
        config.build_settings['CODE_SIGNING_REQUIRED'] = 'YES'
        config.build_settings['CODE_SIGNING_ALLOWED'] = 'YES'
        config.build_settings.delete('CODE_SIGN_IDENTITY') # Let Xcode choose automatically
        config.build_settings.delete('PROVISIONING_PROFILE_SPECIFIER') # Let Xcode pick automatically
EOF
else
    echo "🔧 Using manual signing for production distribution"
    cat >> Podfile <<EOF
        # Production distribution - Manual code signing
        config.build_settings['CODE_SIGN_STYLE'] = 'Manual'
        config.build_settings['DEVELOPMENT_TEAM'] = '$team_id'
        config.build_settings['CODE_SIGN_IDENTITY'] = 'Apple Distribution'
        config.build_settings['CODE_SIGNING_REQUIRED'] = 'YES'
        config.build_settings['CODE_SIGNING_ALLOWED'] = 'YES'
        config.build_settings.delete('PROVISIONING_PROFILE_SPECIFIER') # Let Xcode pick automatically
EOF
fi

# Add common settings
cat >> Podfile <<EOF
        config.build_settings.delete('EXPANDED_CODE_SIGN_IDENTITY')
        config.build_settings.delete('CODE_SIGN_ENTITLEMENTS') # Handled by Runner target entitlements
        # Ensure Pods do NOT have OTHER_CODE_SIGN_FLAGS pointing to a specific keychain
        config.build_settings.delete('OTHER_CODE_SIGN_FLAGS')

        # Other common settings
        config.build_settings['ENABLE_BITCODE'] = 'NO'
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '$deployment_target'
        if config.build_settings['SDKROOT'] == 'iphoneos'
          config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
        end
      end
    end
  end
end
EOF

echo "✅ Podfile generated with deployment target: $deployment_target, team ID: $team_id, export method: $export_method"

# Install CocoaPods dependencies
echo "📥 Installing CocoaPods dependencies..."
# Clean pod cache for a fresh start
pod cache clean --all || true # Allow failure if cache is empty
# Deintegrate and Install
pod deintegrate || true # Allow failure if not integrated
if ! pod install --repo-update; then
    echo "❌ pod install failed"
    echo "This could be due to:"
    echo "1. Network connectivity issues"
    echo "2. CocoaPods repository issues"
    echo "3. Flutter dependencies not properly configured"
    echo "4. iOS deployment target compatibility issues"
    exit 1
fi
echo "✅ CocoaPods installation complete."

cd ..

echo "✅ CocoaPods setup completed successfully" 