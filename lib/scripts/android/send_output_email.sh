#!/bin/bash

# Send Output Email Script
# This script sends an email with all files in the output folder as attachments

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
OUTPUT_DIR="$PROJECT_ROOT/output"

# Load email templates
if [ -f "$SCRIPT_DIR/../email_templates.sh" ]; then
    source "$SCRIPT_DIR/../email_templates.sh"
    echo "✅ Email templates loaded successfully"
else
    echo "❌ Email templates not found"
    exit 1
fi

# Load centralized email configuration
echo "📧 Loading email configuration..."
if [ -f "$SCRIPT_DIR/../email_config.sh" ]; then
    source "$SCRIPT_DIR/../email_config.sh"
    echo "✅ Email configuration loaded successfully"
else
    echo "⚠️  Email configuration file not found, using fallback values"
    # Fallback configuration
    SMTP_SERVER="${SMTP_SERVER:-smtp.gmail.com}"
    SMTP_PORT="${SMTP_PORT:-587}"
    SMTP_USER="${SMTP_USERNAME:-prasannasrie@gmail.com}"
    SMTP_PASS="${SMTP_PASSWORD:-jbbf nzhm zoay lbwb}"
    FROM_EMAIL="${FROM_EMAIL:-no-reply@quikapp.co}"
fi

# Source environment variables to get EMAIL_ID
if [ -z "$CI" ] && [ -f "$SCRIPT_DIR/export.sh" ]; then
    source "$SCRIPT_DIR/export.sh"
fi

# --- EMAIL CONFIGURATION ---
TO="${EMAIL_ID:-support@quikapp.co}"
SUBJECT="QuikApp Build Report - $(date '+%Y-%m-%d %H:%M:%S')"

# Generate artifact list for HTML template
ARTIFACT_LIST=""
if [ -d "$OUTPUT_DIR" ]; then
    for file in "$OUTPUT_DIR"/*; do
        [ -e "$file" ] || continue
        ARTIFACT_LIST+="<li>$(basename "$file")</li>"
    done
fi

# Determine build status and generate appropriate email content
if [ -f "$OUTPUT_DIR/app-release.apk" ] || [ -f "$OUTPUT_DIR/app-release.aab" ]; then
    BUILD_STATUS="✅ SUCCESS"
    STATUS_COLOR="SUCCESS"
    # Generate success email content
    EMAIL_CONTENT=$(SUCCESS_TEMPLATE)
else
    BUILD_STATUS="❌ FAILED"
    STATUS_COLOR="FAILED"
    # Get error details from build log if available
    ERROR_DETAILS=""
    if [ -f "flutter_build_apk.log" ]; then
        ERROR_DETAILS=$(tail -50 flutter_build_apk.log 2>/dev/null || echo "No build log available")
    else
        ERROR_DETAILS="Build artifacts not found. Please check the build logs for more details."
    fi
    # Generate error email content
    EMAIL_CONTENT=$(ERROR_TEMPLATE)
fi

echo -e "${BLUE}📧 Sending email with build outputs...${NC}"
echo -e "${BLUE}📧 To: $TO${NC}"
echo -e "${BLUE}📧 From: $FROM_EMAIL${NC}"
echo -e "${BLUE}📧 Status: $BUILD_STATUS${NC}"

# Check for email sending tools
if command -v python3 &> /dev/null; then
    echo -e "${BLUE}📤 Using Python to send email...${NC}"
    # Create a temporary Python script for sending HTML email
    TMP_PY=$(mktemp)
    cat > "$TMP_PY" << EOF
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.application import MIMEApplication
import os

# Email configuration
smtp_server = "$SMTP_SERVER"
smtp_port = $SMTP_PORT
smtp_user = "$SMTP_USER"
smtp_pass = "$SMTP_PASS"
from_email = "$FROM_EMAIL"
to_email = "$TO"
subject = "$SUBJECT"

# Create message
msg = MIMEMultipart('alternative')
msg['Subject'] = subject
msg['From'] = from_email
msg['To'] = to_email

# Attach HTML content
html_part = MIMEText('''$EMAIL_CONTENT''', 'html')
msg.attach(html_part)

# Attach files from output directory
output_dir = "$OUTPUT_DIR"
if os.path.exists(output_dir):
    for filename in os.listdir(output_dir):
        filepath = os.path.join(output_dir, filename)
        if os.path.isfile(filepath):
            with open(filepath, 'rb') as f:
                part = MIMEApplication(f.read(), Name=filename)
                part['Content-Disposition'] = f'attachment; filename="{filename}"'
                msg.attach(part)

# Send email
with smtplib.SMTP(smtp_server, smtp_port) as server:
    server.starttls()
    server.login(smtp_user, smtp_pass)
    server.send_message(msg)
EOF
    python3 "$TMP_PY"
    rm "$TMP_PY"
    echo -e "${GREEN}✅ Email sent successfully using Python${NC}"
    
elif command -v mutt &> /dev/null; then
    echo -e "${BLUE}📤 Using mutt to send email...${NC}"
    
    # Create a temporary HTML file
    TMP_HTML=$(mktemp)
    echo "$EMAIL_CONTENT" > "$TMP_HTML"
    
    # Compose attachments list for mutt
    ATTACHMENTS=()
    if [ -d "$OUTPUT_DIR" ]; then
        for file in "$OUTPUT_DIR"/*; do
            [ -e "$file" ] || continue
            ATTACHMENTS+=("-a" "$file")
        done
    fi
    
    echo -e "${BLUE}📎 Attaching files:${NC}"
    if [ -d "$OUTPUT_DIR" ]; then
        for file in "$OUTPUT_DIR"/*; do
            [ -e "$file" ] || continue
            echo -e "${GREEN}   - $(basename "$file")${NC}"
        done
    fi
    
    echo "$EMAIL_CONTENT" | mutt -e "set content_type=text/html" -s "$SUBJECT" "${ATTACHMENTS[@]}" -- "$TO"
    rm "$TMP_HTML"
    echo -e "${GREEN}✅ Email sent successfully using mutt${NC}"
    
elif command -v msmtp &> /dev/null; then
    echo -e "${BLUE}📤 Using msmtp to send email...${NC}"
    
    # Create a temporary email file
    TMPMAIL=$(mktemp)
    {
        echo "Subject: $SUBJECT"
        echo "From: $FROM_EMAIL"
        echo "To: $TO"
        echo "MIME-Version: 1.0"
        echo "Content-Type: multipart/mixed; boundary=\"sep\""
        echo
        echo "--sep"
        echo "Content-Type: text/html; charset=UTF-8"
        echo
        echo "$EMAIL_CONTENT"
        
        if [ -d "$OUTPUT_DIR" ]; then
            for file in "$OUTPUT_DIR"/*; do
                [ -e "$file" ] || continue
                FILENAME=$(basename "$file")
                echo "--sep"
                echo "Content-Type: application/octet-stream; name=\"$FILENAME\""
                echo "Content-Disposition: attachment; filename=\"$FILENAME\""
                echo "Content-Transfer-Encoding: base64"
                echo
                base64 "$file"
            done
        fi
        echo "--sep--"
    } > "$TMPMAIL"
    
    msmtp -a default --from="$FROM_EMAIL" "$TO" < "$TMPMAIL"
    rm "$TMPMAIL"
    echo -e "${GREEN}✅ Email sent successfully using msmtp${NC}"
else
    echo -e "${RED}❌ No email sending tools found (python3, mutt, or msmtp)${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Email with build outputs sent successfully!${NC}"
echo -e "${YELLOW}📧 Email sent to: $TO${NC}"
echo -e "${YELLOW}📧 Subject: $SUBJECT${NC}"
echo -e "${YELLOW}📧 Status: $BUILD_STATUS${NC}" 