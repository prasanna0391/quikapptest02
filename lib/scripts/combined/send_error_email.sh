#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Source environment variables
. "$SCRIPT_DIR/export.sh"

# Function to send email using configured SMTP
send_email() {
    local subject="$1"
    local body="$2"
    local recipient="$EMAIL_ID"

    # Check if email configuration is available
    if [ -z "$SMTP_SERVER" ] || [ -z "$SMTP_USERNAME" ] || [ -z "$SMTP_PASSWORD" ] || [ -z "$recipient" ]; then
        echo "⚠️ Email configuration is incomplete. Skipping notification."
        return 1
    fi

    echo "📧 Sending error notification email to $recipient..."
    echo "📧 Using configured SMTP service: $SMTP_SERVER"

    # Create temporary email file
    local email_file=$(mktemp)
    cat > "$email_file" << EOF
From: $SMTP_USERNAME
To: $recipient
Subject: $subject
Content-Type: text/plain; charset=UTF-8

$body

Build Details:
-------------
App: $APP_NAME
Version: $VERSION_NAME ($VERSION_CODE)
Package: $PKG_NAME
Bundle ID: $BUNDLE_ID

Environment:
-----------
Android SDK: $ANDROID_HOME
Flutter SDK: $(dirname $(dirname $(which flutter)))
Build Time: $(date)

Build Configuration:
------------------
Push Notifications: $PUSH_NOTIFY
Firebase: ${FIREBASE_CONFIG_ANDROID:+Android} ${FIREBASE_CONFIG_IOS:+iOS}
Build Type: ${EXPORT_METHOD:-release}

Error Details:
-------------
$body

EOF

    # Send email using curl
    if curl -s --url "smtp://$SMTP_SERVER:$SMTP_PORT" \
        --mail-from "$SMTP_USERNAME" \
        --mail-rcpt "$recipient" \
        --ssl-reqd \
        --user "$SMTP_USERNAME:$SMTP_PASSWORD" \
        --upload-file "$email_file"; then
        echo "✅ Email sent successfully!"
    else
        echo "❌ Failed to send email"
    fi

    # Clean up
    rm -f "$email_file"
}

# Check if required parameters are provided
if [ $# -lt 2 ]; then
    echo "❌ Usage: $0 <subject> <message>"
    exit 1
fi

# Send error email
send_email "$1" "$2" 