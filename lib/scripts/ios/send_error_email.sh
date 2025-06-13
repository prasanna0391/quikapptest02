#!/usr/bin/env bash

set -euo pipefail

# Email notification script for iOS build errors
# This script sends detailed error reports with greetings, error causes, steps to fix, and project details

# Function to get current timestamp
get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S %Z'
}

# Function to analyze error and provide solutions
analyze_error() {
    local error_message="$1"
    local error_cause=""
    local steps_to_fix=""
    
    # Analyze common iOS build errors
    if echo "$error_message" | grep -q "CodeSign.*failed"; then
        error_cause="Code signing failure - Certificate or provisioning profile mismatch"
        steps_to_fix="1. Verify certificate and provisioning profile are correctly installed\n2. Check that the certificate is included in the provisioning profile\n3. Ensure the bundle identifier matches the provisioning profile\n4. Try using automatic signing instead of manual signing\n5. Clean and rebuild the project"
    elif echo "$error_message" | grep -q "CocoaPods.*not found"; then
        error_cause="CocoaPods not installed or not in PATH"
        steps_to_fix="1. Install CocoaPods: sudo gem install cocoapods\n2. Or install via Homebrew: brew install cocoapods\n3. Verify installation: pod --version\n4. Run pod setup to initialize CocoaPods"
    elif echo "$error_message" | grep -q "Provisioning profile.*not found"; then
        error_cause="Provisioning profile not found or invalid"
        steps_to_fix="1. Download the correct provisioning profile from Apple Developer portal\n2. Install the profile: double-click the .mobileprovision file\n3. Verify the profile is installed in Xcode preferences\n4. Check that the profile matches your bundle identifier"
    elif echo "$error_message" | grep -q "Certificate.*not found"; then
        error_cause="Code signing certificate not found or invalid"
        steps_to_fix="1. Download the correct certificate from Apple Developer portal\n2. Install the certificate: double-click the .cer file\n3. Import the private key if required\n4. Verify the certificate is in Keychain Access"
    elif echo "$error_message" | grep -q "Entitlements.*mismatch"; then
        error_cause="Entitlements file mismatch with provisioning profile"
        steps_to_fix="1. Check that entitlements match the provisioning profile capabilities\n2. Verify get-task-allow setting matches profile type (development/production)\n3. Ensure aps-environment matches profile type\n4. Regenerate entitlements file if needed"
    elif echo "$error_message" | grep -q "Archive.*failed"; then
        error_cause="Xcode archive process failed"
        steps_to_fix="1. Clean the build folder: Product > Clean Build Folder\n2. Delete derived data: Xcode > Preferences > Locations > Derived Data > Delete\n3. Check for any build script errors\n4. Verify all required files are present"
    else
        error_cause="Unknown build error - General compilation or configuration issue"
        steps_to_fix="1. Clean the project: flutter clean && flutter pub get\n2. Update all dependencies: flutter upgrade\n3. Check Xcode project settings\n4. Verify all required certificates and profiles are installed\n5. Check for any syntax errors in code\n6. Review the complete build log for specific error details"
    fi
    
    echo "$error_cause|$steps_to_fix"
}

# Function to send error email
send_error_email() {
    local error_message="$1"
    local build_log="$2"
    local script_name="$3"
    
    # Check if email configuration is available
    if [ -z "${SMTP_SERVER:-}" ] || [ -z "${SMTP_USERNAME:-}" ] || [ -z "${SMTP_PASSWORD:-}" ] || [ -z "${EMAIL_ID:-}" ]; then
        echo "⚠️ Email configuration not found. Skipping email notification."
        echo "Please configure SMTP_SERVER, SMTP_USERNAME, SMTP_PASSWORD, and EMAIL_ID in export.sh"
        return 0
    fi
    
    # Analyze the error
    local analysis=$(analyze_error "$error_message")
    local error_cause=$(echo "$analysis" | cut -d'|' -f1)
    local steps_to_fix=$(echo "$analysis" | cut -d'|' -f2)
    
    # Create email content
    cat > /tmp/error_email.txt <<EMAILCONTENT
iOS Build Error Alert - ${APP_NAME:-Unknown App} v${VERSION_NAME:-Unknown Version}
================================================

Greetings!

We've detected an error during the iOS build process for your project ${APP_NAME:-Unknown App}. 
This email contains detailed information about the error and steps to resolve it.

ERROR DETAILS:
- Error Type: $error_cause
- Failed Script: $script_name
- Time: $(get_timestamp)

Error Message:
$(echo "$error_message" | head -10)

STEPS TO FIX:
$steps_to_fix

PROJECT INFORMATION:
- App Name: ${APP_NAME:-Unknown}
- Bundle ID: ${BUNDLE_ID:-Unknown}
- Version: ${VERSION_NAME:-Unknown} (${VERSION_CODE:-Unknown})
- Team ID: ${APPLE_TEAM_ID:-Unknown}
- Export Method: ${EXPORT_METHOD:-Unknown}
- Profile Type: $([ "${IS_DEVELOPMENT_PROFILE:-false}" = "true" ] && echo "Development" || echo "Production")

SYSTEM INFORMATION:
- System: $(uname -s) $(uname -r)
- User: $(whoami)
- Working Directory: $(pwd)

ADDITIONAL SUPPORT:
If you continue to experience issues after trying the steps above, please:
- Check the complete build log for more detailed error information
- Verify all certificates and provisioning profiles are up to date
- Ensure your Apple Developer account has the necessary permissions
- Contact your development team for additional assistance

---
This is an automated error notification from your iOS build system.
Generated on $(get_timestamp) | Project: ${APP_NAME:-Unknown} | Version: ${VERSION_NAME:-Unknown}
EMAILCONTENT

    # Send email using curl (if available)
    if command -v curl >/dev/null 2>&1; then
        echo "📧 Sending error notification email to $EMAIL_ID..."
        
        # For Gmail SMTP
        if [ "$SMTP_SERVER" = "smtp.gmail.com" ]; then
            curl -s --url "smtps://$SMTP_SERVER:465" \
                --mail-from "$SMTP_USERNAME" \
                --mail-rcpt "$EMAIL_ID" \
                --user "$SMTP_USERNAME:$SMTP_PASSWORD" \
                --upload-file /tmp/error_email.txt \
                --ssl-reqd || echo "⚠️ Failed to send email via curl"
        else
            echo "⚠️ SMTP server $SMTP_SERVER not configured for curl. Please check email configuration."
        fi
    else
        echo "⚠️ curl not available. Email content saved to /tmp/error_email.txt"
        echo "📧 Email content prepared but not sent. Please check the file manually."
    fi
    
    # Clean up temporary files
    rm -f /tmp/error_email.txt
}

# Function to send success email
send_success_email() {
    local script_name="$1"
    local build_time="$2"
    
    # Check if email configuration is available
    if [ -z "${SMTP_SERVER:-}" ] || [ -z "${SMTP_USERNAME:-}" ] || [ -z "${SMTP_PASSWORD:-}" ] || [ -z "${EMAIL_ID:-}" ]; then
        echo "⚠️ Email configuration not found. Skipping success notification."
        return 0
    fi
    
    # Create success email content
    cat > /tmp/success_email.txt <<EMAILCONTENT
iOS Build Success - ${APP_NAME:-Unknown App} v${VERSION_NAME:-Unknown Version}
============================================

Greetings!

Great news! The iOS build process for your project ${APP_NAME:-Unknown App} has completed successfully.

BUILD DETAILS:
- App Name: ${APP_NAME:-Unknown}
- Bundle ID: ${BUNDLE_ID:-Unknown}
- Version: ${VERSION_NAME:-Unknown} (${VERSION_CODE:-Unknown})
- Team ID: ${APPLE_TEAM_ID:-Unknown}
- Export Method: ${EXPORT_METHOD:-Unknown}
- Profile Type: $([ "${IS_DEVELOPMENT_PROFILE:-false}" = "true" ] && echo "Development" || echo "Production")
- Build Time: $build_time
- Completed Script: $script_name

SYSTEM INFORMATION:
- System: $(uname -s) $(uname -r)
- User: $(whoami)
- Working Directory: $(pwd)

NEXT STEPS:
- The IPA file should be available in the build directory
- You can now install the app on your device or submit to App Store
- Make sure to test the app thoroughly before distribution

---
This is an automated success notification from your iOS build system.
Generated on $(get_timestamp) | Project: ${APP_NAME:-Unknown} | Version: ${VERSION_NAME:-Unknown}
EMAILCONTENT

    # Send email using curl (if available)
    if command -v curl >/dev/null 2>&1; then
        echo "📧 Sending success notification email to $EMAIL_ID..."
        
        # For Gmail SMTP
        if [ "$SMTP_SERVER" = "smtp.gmail.com" ]; then
            curl -s --url "smtps://$SMTP_SERVER:465" \
                --mail-from "$SMTP_USERNAME" \
                --mail-rcpt "$EMAIL_ID" \
                --user "$SMTP_USERNAME:$SMTP_PASSWORD" \
                --upload-file /tmp/success_email.txt \
                --ssl-reqd || echo "⚠️ Failed to send success email via curl"
        else
            echo "⚠️ SMTP server $SMTP_SERVER not configured for curl. Please check email configuration."
        fi
    else
        echo "⚠️ curl not available. Success email content saved to /tmp/success_email.txt"
    fi
    
    # Clean up temporary files
    rm -f /tmp/success_email.txt
}

# Main function to handle error reporting
report_error() {
    local error_message="$1"
    local build_log="$2"
    local script_name="$3"
    
    echo "🚨 Error detected in $script_name"
    echo "📧 Preparing error notification email..."
    
    # Send error email
    send_error_email "$error_message" "$build_log" "$script_name"
    
    echo "✅ Error notification process completed"
}

# Main function to handle success reporting
report_success() {
    local script_name="$1"
    local build_time="$2"
    
    echo "✅ Build completed successfully in $script_name"
    echo "📧 Preparing success notification email..."
    
    # Send success email
    send_success_email "$script_name" "$build_time"
    
    echo "✅ Success notification process completed"
}

# Export functions for use in other scripts
export -f report_error
export -f report_success
export -f send_error_email
export -f send_success_email

# If script is called directly, show usage
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "📧 iOS Build Email Notification System"
    echo ""
    echo "Usage:"
    echo "  source ./send_error_email.sh"
    echo "  report_error \"Error message\" \"build_log\" \"script_name\""
    echo "  report_success \"script_name\" \"build_time\""
    echo ""
    echo "Or call the functions directly:"
    echo "  send_error_email \"Error message\" \"build_log\" \"script_name\""
    echo "  send_success_email \"script_name\" \"build_time\""
fi
