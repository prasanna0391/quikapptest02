#!/bin/bash

# Send Error Email Notification Script
# This script sends error notifications when the build fails

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Function to send email using curl
send_error_email() {
    local error_message="$1"
    local error_details="$2"
    local resolve_steps="$3"
    
    # Get recipient email from environment variable
    local recipient_email="${EMAIL_ID:-prasannasrie@gmail.com}"
    
    # Email content
    local subject="Build Failed - Garbcode App Android Build"
    local from_email="build@quikapp.co"
    
    # Create HTML email content
    local html_content=$(cat << EOF
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Build Failed - Garbcode App</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background-color: #dc3545; color: white; padding: 20px; text-align: center; border-radius: 5px 5px 0 0; }
        .content { background-color: #f8f9fa; padding: 20px; border-radius: 0 0 5px 5px; }
        .error-section { background-color: #fff3cd; border: 1px solid #ffeaa7; padding: 15px; margin: 15px 0; border-radius: 5px; }
        .resolve-section { background-color: #d1ecf1; border: 1px solid #bee5eb; padding: 15px; margin: 15px 0; border-radius: 5px; }
        .footer { text-align: center; margin-top: 20px; color: #6c757d; font-size: 12px; }
        .greeting { font-size: 18px; margin-bottom: 20px; }
        .error-title { color: #dc3545; font-weight: bold; }
        .resolve-title { color: #0c5460; font-weight: bold; }
        pre { background-color: #f8f9fa; padding: 10px; border-radius: 3px; overflow-x: auto; white-space: pre-wrap; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚨 Build Failed</h1>
            <p>Garbcode App Android Build Process</p>
        </div>
        
        <div class="content">
            <div class="greeting">
                <strong>Hello,</strong><br>
                The Android build process for Garbcode App has encountered an error and failed to complete successfully.
            </div>
            
            <div class="error-section">
                <div class="error-title">❌ Error Summary:</div>
                <p>${error_message}</p>
            </div>
            
            <div class="error-section">
                <div class="error-title">📋 Error Details:</div>
                <pre>${error_details}</pre>
            </div>
            
            <div class="resolve-section">
                <div class="resolve-title">🔧 Resolution Steps:</div>
                <ol>
                    ${resolve_steps}
                </ol>
            </div>
            
            <div style="margin-top: 20px; padding: 15px; background-color: #e9ecef; border-radius: 5px;">
                <strong>Build Information:</strong><br>
                • Project: Garbcode App<br>
                • Package: ${PKG_NAME:-com.garbcode.garbcodeapp}<br>
                • Version: ${VERSION_NAME:-1.0.0}<br>
                • Build Time: $(date '+%Y-%m-%d %H:%M:%S')<br>
                • Build ID: $(date '+%Y%m%d_%H%M%S')
            </div>
        </div>
        
        <div class="footer">
            <p>This is an automated notification from the QuikApp build system.</p>
            <p>If you have any questions, please contact the development team.</p>
        </div>
    </div>
</body>
</html>
EOF
)

    # Try to send email using curl (if available)
    if command -v curl >/dev/null 2>&1; then
        echo -e "${BLUE}📧 Sending error notification email to ${recipient_email}...${NC}"
        
        # Check if email service is configured
        if [ -n "${SMTP_SERVER:-}" ] && [ -n "${SMTP_USERNAME:-}" ] && [ -n "${SMTP_PASSWORD:-}" ]; then
            echo -e "${GREEN}📧 Using configured SMTP service: ${SMTP_SERVER}${NC}"
            
            # Create email content for SMTP
            local email_content=$(cat << EOF
From: ${from_email}
To: ${recipient_email}
Subject: ${subject}
MIME-Version: 1.0
Content-Type: text/html; charset=UTF-8

${html_content}
EOF
)
            
            # Send email using curl with SMTP
            if curl -s --url "smtp://${SMTP_SERVER}:587" \
                --mail-from "${from_email}" \
                --mail-rcpt "${recipient_email}" \
                --user "${SMTP_USERNAME}:${SMTP_PASSWORD}" \
                --upload-file <(echo "$email_content") \
                --ssl-reqd; then
                echo -e "${GREEN}✅ Email sent successfully!${NC}"
            else
                echo -e "${YELLOW}⚠️  SMTP email sending failed, saving to file instead${NC}"
                # Save email content to file for debugging
                local email_file="${PROJECT_ROOT}/build_error_email_$(date +%Y%m%d_%H%M%S).html"
                echo "$html_content" > "$email_file"
                echo -e "${GREEN}✅ Error email content saved to: ${email_file}${NC}"
            fi
        else
            echo -e "${YELLOW}⚠️  Email service not configured, saving to file instead${NC}"
            echo -e "${YELLOW}💡 To enable email sending, set SMTP_SERVER, SMTP_USERNAME, and SMTP_PASSWORD in export.sh${NC}"
            echo -e "${YELLOW}📧 Would send email to: ${recipient_email}${NC}"
            echo -e "${YELLOW}📧 From: ${from_email}${NC}"
            echo -e "${YELLOW}📧 Subject: ${subject}${NC}"
            
            # Save email content to file for debugging
            local email_file="${PROJECT_ROOT}/build_error_email_$(date +%Y%m%d_%H%M%S).html"
            echo "$html_content" > "$email_file"
            echo -e "${GREEN}✅ Error email content saved to: ${email_file}${NC}"
        fi
        
    else
        echo -e "${RED}❌ curl not found - cannot send email notification${NC}"
        echo -e "${YELLOW}💡 Please install curl or configure an alternative email sending method${NC}"
        
        # Save email content to file for debugging
        local email_file="${PROJECT_ROOT}/build_error_email_$(date +%Y%m%d_%H%M%S).html"
        echo "$html_content" > "$email_file"
        echo -e "${GREEN}✅ Error email content saved to: ${email_file}${NC}"
    fi
}

# Function to generate resolve steps based on error type
generate_resolve_steps() {
    local error_type="$1"
    
    case "$error_type" in
        "v1_embedding")
            echo "<li>Run the fix_v1_embedding.sh script to resolve Android v1 embedding issues</li>"
            echo "<li>Ensure all Android files are using v2 embedding</li>"
            echo "<li>Clean the build cache with 'flutter clean'</li>"
            ;;
        "missing_resource")
            echo "<li>Check that all required resource files exist in android/app/src/main/res/</li>"
            echo "<li>Verify that launcher icons are properly configured</li>"
            echo "<li>Run 'flutter pub get' to ensure all dependencies are downloaded</li>"
            ;;
        "google_services")
            echo "<li>Verify that google-services.json is properly configured</li>"
            echo "<li>Check that the package name in google-services.json matches your app's package name</li>"
            echo "<li>Ensure Firebase project is properly set up</li>"
            ;;
        "compilation")
            echo "<li>Check for syntax errors in Kotlin/Java files</li>"
            echo "<li>Verify that all required imports are present</li>"
            echo "<li>Run 'flutter clean' and try building again</li>"
            ;;
        "gradle")
            echo "<li>Check Gradle configuration files for errors</li>"
            echo "<li>Verify that all dependencies are compatible</li>"
            echo "<li>Try updating Gradle version if needed</li>"
            ;;
        *)
            echo "<li>Review the error details above for specific issues</li>"
            echo "<li>Check the build logs for more information</li>"
            echo "<li>Run 'flutter clean' and try building again</li>"
            echo "<li>Contact the development team if the issue persists</li>"
            ;;
    esac
}

# Function to detect error type from error message
detect_error_type() {
    local error_message="$1"
    
    if echo "$error_message" | grep -qi "v1 embedding\|FlutterApplication\|FlutterActivity"; then
        echo "v1_embedding"
    elif echo "$error_message" | grep -qi "resource.*not found\|mipmap\|drawable"; then
        echo "missing_resource"
    elif echo "$error_message" | grep -qi "google-services\|Firebase\|package name"; then
        echo "google_services"
    elif echo "$error_message" | grep -qi "compilation\|syntax\|import"; then
        echo "compilation"
    elif echo "$error_message" | grep -qi "gradle\|build.gradle"; then
        echo "gradle"
    else
        echo "unknown"
    fi
}

# Main function to handle error notification
main() {
    local error_message="$1"
    local error_details="$2"
    
    if [ -z "$error_message" ]; then
        error_message="Build process failed with an unknown error"
    fi
    
    if [ -z "$error_details" ]; then
        error_details="No additional error details available"
    fi
    
    # Detect error type
    local error_type=$(detect_error_type "$error_message")
    
    # Generate resolve steps
    local resolve_steps=$(generate_resolve_steps "$error_type")
    
    # Send email
    send_error_email "$error_message" "$error_details" "$resolve_steps"
}

# If script is called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 