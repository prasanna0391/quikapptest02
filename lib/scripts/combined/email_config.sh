#!/bin/bash

# Load the main email configuration
source "$(dirname "$(dirname "$0")")/email_config.sh"

# Combined workflow-specific email configuration
export EMAIL_SUBJECT="Combined Build Notification"
export EMAIL_BODY="Combined Android and iOS build completed successfully."
export EMAIL_ERROR_SUBJECT="Combined Build Failed"
export EMAIL_ERROR_BODY="Combined Android and iOS build failed. Please check the build logs for details."

# Validate combined workflow-specific configuration
if [ -z "$EMAIL_SUBJECT" ] || [ -z "$EMAIL_BODY" ] || [ -z "$EMAIL_ERROR_SUBJECT" ] || [ -z "$EMAIL_ERROR_BODY" ]; then
    echo "❌ Combined workflow email configuration is incomplete"
    exit 1
fi

echo "✅ Combined workflow email configuration loaded successfully" 