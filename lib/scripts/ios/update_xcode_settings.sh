#!/usr/bin/env bash

set -euo pipefail

echo "🛠️ Updating Xcode project settings for code signing..."

# Check if required environment variables are set
if [ -z "${APPLE_TEAM_ID:-}" ]; then
    echo "❌ Error: APPLE_TEAM_ID environment variable is not set"
    exit 1
fi

if [ -z "${BUNDLE_ID:-}" ]; then
    echo "❌ Error: BUNDLE_ID environment variable is not set"
    exit 1
fi

# Set local variables
apple_team_id="$APPLE_TEAM_ID"
bundle_id="$BUNDLE_ID"
profile_path="${PROFILE_PATH:-build/profile.mobileprovision}"

# Determine if we're using a development or production profile
is_development_profile="${IS_DEVELOPMENT_PROFILE:-true}"
is_production_profile="${IS_PRODUCTION_PROFILE:-false}"

echo "🛠️ Updating Xcode project settings for code signing..."
echo "🔧 Profile Type: $([ "$is_development_profile" = "true" ] && echo "Development" || echo "Production")"

# Install provisioning profile
echo "📱 Installing provisioning profile..."
if [ -f "$profile_path" ]; then
    # Get the profile UUID using a temporary file
    temp_plist="/tmp/temp_profile_$$.plist"
    security cms -D -i "$profile_path" > "$temp_plist"
    profile_uuid=$(/usr/libexec/PlistBuddy -c "Print :UUID" "$temp_plist" 2>/dev/null || echo "")
    rm -f "$temp_plist"
    
    if [ -n "$profile_uuid" ]; then
        echo "✅ Found profile UUID: $profile_uuid"
        
        # Install the profile
        mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles/
        cp "$profile_path" ~/Library/MobileDevice/Provisioning\ Profiles/"$profile_uuid".mobileprovision
        echo "✅ Provisioning profile installed"
        
        # Export UUID for Ruby script
        export PROFILE_UUID="$profile_uuid"
    else
        echo "❌ Could not extract profile UUID"
        exit 1
    fi
else
    echo "❌ Provisioning profile not found at $profile_path"
    exit 1
fi

cd ios

# Check if xcodeproj gem is available
if ! gem list xcodeproj -i > /dev/null 2>&1; then
    echo "⚠️ xcodeproj gem not found, installing..."
    if ! gem install xcodeproj; then
        echo "❌ Failed to install xcodeproj gem"
        echo "Please install it manually: gem install xcodeproj"
        exit 1
    fi
fi

ruby <<EOF
require 'xcodeproj'
project = Xcodeproj::Project.open('Runner.xcodeproj')
project.targets.each do |target|
  if target.name == 'Runner'
    target.build_configurations.each do |config|
      if ENV['IS_DEVELOPMENT_PROFILE'] == 'true'
        # Use automatic signing for development profiles
        puts "🔧 Setting automatic signing for development profile"
        config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
        config.build_settings['DEVELOPMENT_TEAM'] = ENV['APPLE_TEAM_ID']
        config.build_settings.delete('PROVISIONING_PROFILE_SPECIFIER')
        config.build_settings.delete('CODE_SIGN_IDENTITY')
        config.build_settings['CODE_SIGNING_REQUIRED'] = 'YES'
        config.build_settings['CODE_SIGNING_ALLOWED'] = 'YES'
        config.build_settings.delete('EXPANDED_CODE_SIGN_IDENTITY')
        config.build_settings['CODE_SIGN_INJECT_BASE_ENTITLEMENTS'] = 'YES'
        config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'Runner/Runner.entitlements'
        config.build_settings.delete('OTHER_CODE_SIGN_FLAGS')
      else
        # Use manual signing for production profiles
        puts "🔧 Setting manual signing for production profile"
        config.build_settings['CODE_SIGN_STYLE'] = 'Manual'
        config.build_settings['DEVELOPMENT_TEAM'] = ENV['APPLE_TEAM_ID']
        config.build_settings['PROVISIONING_PROFILE_SPECIFIER'] = ENV['PROFILE_UUID'] || ''
        config.build_settings['CODE_SIGN_IDENTITY'] = 'Apple Distribution'
        config.build_settings['CODE_SIGNING_REQUIRED'] = 'YES'
        config.build_settings['CODE_SIGNING_ALLOWED'] = 'YES'
        config.build_settings.delete('EXPANDED_CODE_SIGN_IDENTITY')
        config.build_settings['CODE_SIGN_INJECT_BASE_ENTITLEMENTS'] = 'YES'
        config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'Runner/Runner.entitlements'
        config.build_settings.delete('OTHER_CODE_SIGN_FLAGS')
      end
    end
  else
    # Ensure Pod targets use automatic signing or inherit from the project
    target.build_configurations.each do |config|
      config.build_settings.delete('CODE_SIGN_STYLE')
      config.build_settings.delete('DEVELOPMENT_TEAM')
      config.build_settings.delete('PROVISIONING_PROFILE_SPECIFIER')
      config.build_settings.delete('CODE_SIGN_IDENTITY')
      config.build_settings.delete('CODE_SIGNING_REQUIRED')
      config.build_settings.delete('CODE_SIGNING_ALLOWED')
      config.build_settings.delete('EXPANDED_CODE_SIGN_IDENTITY')
      config.build_settings.delete('CODE_SIGN_ENTITLEMENTS')
      config.build_settings.delete('OTHER_CODE_SIGN_FLAGS')
    end
  end
end
project.save
EOF

cd ..
echo "✅ Xcode project settings updated successfully" 