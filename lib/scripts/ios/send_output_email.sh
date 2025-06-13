#!/usr/bin/env bash

set -euo pipefail

echo "📧 Sending iOS build success notification..."

# Check if required environment variables are set
if [ -z "${EMAIL_ID:-}" ]; then
    echo "❌ Error: EMAIL_ID environment variable is not set"
    exit 1
fi

if [ -z "${SMTP_SERVER:-}" ]; then
    echo "❌ Error: SMTP_SERVER environment variable is not set"
    exit 1
fi

if [ -z "${SMTP_USERNAME:-}" ]; then
    echo "❌ Error: SMTP_USERNAME environment variable is not set"
    exit 1
fi

if [ -z "${SMTP_PASSWORD:-}" ]; then
    echo "❌ Error: SMTP_PASSWORD environment variable is not set"
    exit 1
fi

# Set local variables
email_id="$EMAIL_ID"
smtp_server="$SMTP_SERVER"
smtp_username="$SMTP_USERNAME"
smtp_password="$SMTP_PASSWORD"
app_name="${APP_NAME:-iOS App}"
version_name="${VERSION_NAME:-1.0.0}"
version_code="${VERSION_CODE:-1}"
bundle_id="${BUNDLE_ID:-unknown}"
web_url="${WEB_URL:-}"
build_timestamp="${BUILD_TIMESTAMP:-$(date +"%Y%m%d_%H%M%S")}"
output_dir="${BUILD_OUTPUT_DIRECTORY:-}"
ipa_path="${FINAL_IPA_PATH:-}"
ipa_size="${IPA_SIZE:-0}"

# Convert IPA size to MB for comparison
ipa_size_mb=$((ipa_size / 1024 / 1024))

echo "📧 Preparing success email..."
echo "  Recipient: $email_id"
echo "  App: $app_name v$version_name+$version_code"
echo "  IPA Size: ${ipa_size_mb}MB"
echo "  Output Directory: $output_dir"

# Create email content
subject="🎉 iOS Build Success: $app_name v$version_name+$version_code"

# Create email body
email_body=$(cat <<EOF
🎉 iOS Build Completed Successfully!

Dear Developer,

Your iOS app build has completed successfully! Here are the details:

📱 App Information:
• App Name: $app_name
• Bundle ID: $bundle_id
• Version: $version_name+$version_code
• Build Timestamp: $build_timestamp

📦 Build Artifacts:
• IPA File: $(basename "$ipa_path" 2>/dev/null || "Not found")
• IPA Size: ${ipa_size_mb}MB
• Output Directory: $output_dir

🔧 Build Configuration:
• iOS Deployment Target: ${IPHONEOS_DEPLOYMENT_TARGET:-unknown}
• Export Method: ${EXPORT_METHOD:-unknown}
• Team ID: ${APPLE_TEAM_ID:-unknown}

✅ Features Enabled:
• Push Notifications: ${PUSH_NOTIFY:-false}
• Camera: ${IS_CAMERA:-false}
• Location: ${IS_LOCATION:-false}
• Microphone: ${IS_MIC:-false}
• Contacts: ${IS_CONTACT:-false}
• Calendar: ${IS_CALENDAR:-false}
• Photo Library: ${IS_PHOTO_LIBRARY:-false}
• Biometric: ${IS_BIOMETRIC:-false}

EOF

# Add app website link if available
if [ -n "$web_url" ]; then
    email_body+=$(cat <<EOF

🌐 App Website: $web_url
EOF
)
fi

# Add attachment information
if [ -n "$ipa_path" ] && [ -f "$ipa_path" ]; then
    if [ "$ipa_size_mb" -lt 25 ]; then
        email_body+=$(cat <<EOF

📎 Attachment: The IPA file is attached to this email (${ipa_size_mb}MB).
EOF
)
    else
        email_body+=$(cat <<EOF

📎 Large File Notice: The IPA file (${ipa_size_mb}MB) is too large for email attachment.
   Please download it from the output directory: $output_dir
EOF
)
    fi
fi

# Add footer
email_body+=$(cat <<EOF

---
This is an automated message from your iOS build system.
Build completed at: $(date)
EOF
)

# Create Python script for sending email
python_script=$(cat <<EOF
import smtplib
import os
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.mime.base import MIMEBase
from email import encoders

# Email configuration
smtp_server = "$smtp_server"
smtp_username = "$smtp_username"
smtp_password = "$smtp_password"
recipient_email = "$email_id"

# Create message
msg = MIMEMultipart()
msg['From'] = smtp_username
msg['To'] = recipient_email
msg['Subject'] = "$subject"

# Add body
msg.attach(MIMEText("""$email_body""", 'plain'))

# Add IPA attachment if under 25MB
ipa_path = "$ipa_path"
ipa_size_mb = $ipa_size_mb

if ipa_path and os.path.exists(ipa_path) and ipa_size_mb < 25:
    try:
        with open(ipa_path, "rb") as attachment:
            part = MIMEBase('application', 'octet-stream')
            part.set_payload(attachment.read())
        
        encoders.encode_base64(part)
        part.add_header(
            'Content-Disposition',
            f'attachment; filename= {os.path.basename(ipa_path)}'
        )
        msg.attach(part)
        print(f"✅ IPA file attached: {os.path.basename(ipa_path)}")
    except Exception as e:
        print(f"⚠️ Failed to attach IPA file: {e}")

# Send email
try:
    server = smtplib.SMTP(smtp_server, 587)
    server.starttls()
    server.login(smtp_username, smtp_password)
    
    text = msg.as_string()
    server.sendmail(smtp_username, recipient_email, text)
    server.quit()
    
    print("✅ Success email sent successfully!")
    print(f"📧 Sent to: {recipient_email}")
    print(f"📎 IPA attached: {'Yes' if ipa_size_mb < 25 and ipa_path and os.path.exists(ipa_path) else 'No'}")
    
except Exception as e:
    print(f"❌ Failed to send email: {e}")
    exit(1)
EOF
)

# Execute Python script
echo "📧 Sending email via Python..."
if echo "$python_script" | python3; then
    echo "✅ Success email sent successfully!"
else
    echo "❌ Failed to send success email"
    exit 1
fi

echo "✅ iOS build success notification completed" 