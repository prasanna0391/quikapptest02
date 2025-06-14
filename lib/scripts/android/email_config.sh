#!/bin/bash

# Email Configuration for QuikApp Build System
# This file contains email configuration settings for build notifications

# QuikApp Details
export QUIKAPP_WEBSITE="https://quikapp.co"
export QUIKAPP_DASHBOARD="https://app.quikapp.co"
export QUIKAPP_DOCS="https://docs.quikapp.co"
export QUIKAPP_SUPPORT="support@quikapp.co"

# Email Recipients
export EMAIL_ID="${EMAIL_ID:-prasannasrie@gmail.com}"  # Primary recipient email
export EMAIL_CC="${EMAIL_CC:-}"  # CC recipients (comma-separated)
export EMAIL_BCC="${EMAIL_BCC:-}"  # BCC recipients (comma-separated)

# SMTP Configuration for Gmail
export EMAIL_SMTP_SERVER="${EMAIL_SMTP_SERVER:-smtp.gmail.com}"
export EMAIL_SMTP_PORT="${EMAIL_SMTP_PORT:-587}"
export EMAIL_SMTP_USER="${EMAIL_SMTP_USER:-prasannasrie@gmail.com}"
export EMAIL_SMTP_PASS="${EMAIL_SMTP_PASS:-jbbf nzhm zoay lbwb}"  # App-specific password for Gmail

# Email Templates
export EMAIL_TEMPLATES_DIR="${SCRIPT_DIR}/email_templates"
export EMAIL_SUCCESS_TEMPLATE="${EMAIL_TEMPLATES_DIR}/success_email.html"
export EMAIL_ERROR_TEMPLATE="${EMAIL_TEMPLATES_DIR}/error_email.html"

# Email Content
export EMAIL_FROM="${EMAIL_FROM:-prasannasrie@gmail.com}"
export EMAIL_FROM_NAME="${EMAIL_FROM_NAME:-QuikApp Build System}"
export EMAIL_SUBJECT_PREFIX="${EMAIL_SUBJECT_PREFIX:-[QuikApp Build]}"

# Function to send email notification
send_email_notification() {
    local type="$1"  # success or error
    local error_message="$2"
    local error_details="$3"
    
    # Check if email configuration is available
    if [ -z "$EMAIL_ID" ]; then
        echo "⚠️  No email recipient configured. Skipping email notification."
        return 0
    fi
    
    # Check if Python email notification script exists
    if [ ! -f "${SCRIPT_DIR}/email_notification.py" ]; then
        echo "❌ Email notification script not found at ${SCRIPT_DIR}/email_notification.py"
        return 1
    fi
    
    # Set environment variables for the Python script
    export APP_NAME="${APP_NAME:-QuikApp Project}"
    export PKG_NAME="${PKG_NAME:-com.quikapp.project}"
    export BUNDLE_ID="${BUNDLE_ID:-com.quikapp.project}"
    export VERSION_NAME="${VERSION_NAME:-1.0.0}"
    export VERSION_CODE="${VERSION_CODE:-1}"
    export WORKFLOW_NAME="${WORKFLOW_NAME:-Android Build}"
    
    # Set QuikApp URLs
    export QUIKAPP_WEBSITE
    export QUIKAPP_DASHBOARD
    export QUIKAPP_DOCS
    export QUIKAPP_SUPPORT
    
    # Run the Python email notification script
    if [ "$type" = "success" ]; then
        python3 "${SCRIPT_DIR}/email_notification.py" "success"
    else
        python3 "${SCRIPT_DIR}/email_notification.py" "error" "$error_message" "$error_details"
    fi
    
    # Check the result
    if [ $? -eq 0 ]; then
        echo "✅ Email notification sent successfully"
        return 0
    else
        echo "❌ Failed to send email notification"
        return 1
    fi
}

# Function to send success notification
send_success_notification() {
    send_email_notification "success"
}

# Function to send error notification
send_error_notification() {
    local error_message="$1"
    local error_details="$2"
    send_email_notification "error" "$error_message" "$error_details"
}

# Export functions
export -f send_email_notification
export -f send_success_notification
export -f send_error_notification

# Load the main email configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../email_config.sh"

# Android-specific email configuration
export EMAIL_SUBJECT="Android Build Notification"
export EMAIL_BODY="Android build completed successfully."
export EMAIL_ERROR_SUBJECT="Android Build Failed"
export EMAIL_ERROR_BODY="Android build failed. Please check the build logs for details."

# Validate Android-specific configuration
if [ -z "$EMAIL_SUBJECT" ] || [ -z "$EMAIL_BODY" ] || [ -z "$EMAIL_ERROR_SUBJECT" ] || [ -z "$EMAIL_ERROR_BODY" ]; then
    echo "❌ Android email configuration is incomplete"
    exit 1
fi

echo "✅ Android email configuration loaded successfully" 