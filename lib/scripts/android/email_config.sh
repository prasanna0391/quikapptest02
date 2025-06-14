#!/bin/bash

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