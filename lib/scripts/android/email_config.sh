#!/bin/bash

# Email Configuration for QuikApp Build System
# This file contains email configuration settings for build notifications

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# QuikApp Project Details
export QUIKAPP_WEBSITE="quikapp.co"
export QUIKAPP_DASHBOARD="app.quikapp.co"
export QUIKAPP_DOCS="docs.quikapp.co"
export QUIKAPP_SUPPORT="support.quikapp.co"

# Email Recipients
export EMAIL_ID="${API_EMAIL_ID:-prasannasrie@gmail.com}"
export EMAIL_CC=""
export EMAIL_BCC=""

# SMTP Configuration
export EMAIL_SMTP_SERVER="smtp.gmail.com"
export EMAIL_SMTP_PORT="587"
export EMAIL_SMTP_USER="${Notifi_E_ID:-prasannasrie@gmail.com}"
export EMAIL_SMTP_PASS="jbbf nzhm zoay lbwb"

# Email Templates
export EMAIL_TEMPLATES_DIR="${SCRIPT_DIR}/../email_templates"
export EMAIL_SUCCESS_TEMPLATE="${EMAIL_TEMPLATES_DIR}/success_email.html"
export EMAIL_ERROR_TEMPLATE="${EMAIL_TEMPLATES_DIR}/error_email.html"

# Email Content
export EMAIL_FROM="${API_EMAIL_ID:-prasannasrie@gmail.com}"
export EMAIL_FROM_NAME="QuikApp Build System"
export EMAIL_SUBJECT_PREFIX="[QuikApp Build]"

# Function to send email notification
send_email_notification() {
    local type="$1"
    local subject="$2"
    local message="$3"
    
    # Check if email configuration is set
    if [ -z "$EMAIL_ID" ] || [ -z "$EMAIL_SMTP_PASS" ]; then
        echo "⚠️ Email configuration not set. Skipping notification."
        return 0
    fi
    
    # Check if Python script exists
    if [ ! -f "${SCRIPT_DIR}/../email_notification.py" ]; then
        echo "⚠️ Email notification script not found. Skipping notification."
        return 0
    fi
    
    # Send email using Python script with proper error handling
    if ! python3 "${SCRIPT_DIR}/../email_notification.py" "$type" "$subject" "$message"; then
        echo "❌ Failed to send email notification"
        echo "💡 Please check your SMTP configuration"
        return 1
    fi
    
    return 0
}

# Function to send success notification
send_success_notification() {
    local subject="${EMAIL_SUBJECT_PREFIX} Build Successful"
    local message="Your QuikApp build has completed successfully."
    send_email_notification "success" "$subject" "$message"
}

# Function to send error notification
send_error_notification() {
    local error_message="$1"
    local error_details="$2"
    local subject="${EMAIL_SUBJECT_PREFIX} Build Failed"
    local message="Error: $error_message\n\nDetails: $error_details"
    send_email_notification "error" "$subject" "$message"
}

# Export functions
export -f send_email_notification
export -f send_success_notification
export -f send_error_notification

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