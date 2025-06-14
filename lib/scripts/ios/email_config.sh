#!/bin/bash

# Load the main email configuration
source "$(dirname "$(dirname "$0")")/email_config.sh"

# iOS-specific email configuration
export EMAIL_SUBJECT="iOS Build Notification"
export EMAIL_BODY="iOS build completed successfully."
export EMAIL_ERROR_SUBJECT="iOS Build Failed"
export EMAIL_ERROR_BODY="iOS build failed. Please check the build logs for details."

# Validate iOS-specific configuration
if [ -z "$EMAIL_SUBJECT" ] || [ -z "$EMAIL_BODY" ] || [ -z "$EMAIL_ERROR_SUBJECT" ] || [ -z "$EMAIL_ERROR_BODY" ]; then
    echo "❌ iOS email configuration is incomplete"
    exit 1
fi

echo "✅ iOS email configuration loaded successfully" 