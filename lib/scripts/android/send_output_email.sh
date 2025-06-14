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

# --- EMAIL CONFIGURATION (Now loaded from email_config.sh) ---
TO="${EMAIL_ID:-support@quikapp.co}"
# FROM_EMAIL is now set by email_config.sh
SUBJECT="QuikApp Build Report - $(date '+%Y-%m-%d %H:%M:%S')"

# Determine build status
if [ -f "$OUTPUT_DIR/app-release.apk" ] || [ -f "$OUTPUT_DIR/app-release.aab" ]; then
    BUILD_STATUS="✅ SUCCESS"
    STATUS_COLOR="SUCCESS"
    BODY="QuikApp build completed successfully!

Build completed at: $(date '+%Y-%m-%d %H:%M:%S')
Project: ${APP_NAME:-QuikApp Project}
Package: ${PKG_NAME:-com.quikapp.project}
Version: ${VERSION_NAME:-1.0.0}
Build Status: SUCCESS

Your mobile app has been successfully generated using QuikApp's platform.
Build artifacts are attached to this email.

Access your app at: https://app.quikapp.co
Visit our website: https://quikapp.co

Best regards,
QuikApp Build System
Convert your website into a mobile app with ease!"
else
    BUILD_STATUS="❌ FAILED"
    STATUS_COLOR="FAILED"
    BODY="QuikApp build failed!

Build attempted at: $(date '+%Y-%m-%d %H:%M:%S')
Project: ${APP_NAME:-QuikApp Project}
Package: ${PKG_NAME:-com.quikapp.project}
Version: ${VERSION_NAME:-1.0.0}
Build Status: FAILED

Reason: Build artifacts not found. Please check the build logs for more details.

Access your dashboard: https://app.quikapp.co
Get support: https://quikapp.co/support

Best regards,
QuikApp Build System
We're here to help you get your app built!"
fi

echo -e "${BLUE}📧 Sending email with build outputs...${NC}"
echo -e "${BLUE}📧 To: $TO${NC}"
echo -e "${BLUE}📧 From: $FROM_EMAIL${NC}"
echo -e "${BLUE}📧 Status: $BUILD_STATUS${NC}"

# Check if output directory exists and has files
if [ ! -d "$OUTPUT_DIR" ]; then
    echo -e "${RED}❌ Output directory not found: $OUTPUT_DIR${NC}"
    # Send failure email even if no output directory
    BODY="QuikApp build failed!

Build attempted at: $(date '+%Y-%m-%d %H:%M:%S')
Project: ${APP_NAME:-QuikApp Project}
Package: ${PKG_NAME:-com.quikapp.project}
Version: ${VERSION_NAME:-1.0.0}
Build Status: FAILED

Reason: Output directory not found. Build process may have failed early.

Access your dashboard: https://app.quikapp.co
Get support: https://quikapp.co/support

Best regards,
QuikApp Build System"
fi

# Check for files in output directory
if [ -z "$(ls -A "$OUTPUT_DIR" 2>/dev/null)" ]; then
    echo -e "${YELLOW}⚠️  No files found in output directory${NC}"
    # Update body for no files case
    BODY="QuikApp build completed but no artifacts found!

Build completed at: $(date '+%Y-%m-%d %H:%M:%S')
Project: ${APP_NAME:-QuikApp Project}
Package: ${PKG_NAME:-com.quikapp.project}
Version: ${VERSION_NAME:-1.0.0}
Build Status: WARNING

Reason: Build completed but no APK or AAB files were generated. Please check the build configuration.

Access your dashboard: https://app.quikapp.co
Get support: https://quikapp.co/support

Best regards,
QuikApp Build System"
fi

# Check for email sending tools
if command -v python3 &> /dev/null; then
    echo -e "${BLUE}📤 Using Python to send email...${NC}"
    python3 "$SCRIPT_DIR/send_output_email.py"
    
elif command -v mutt &> /dev/null; then
    echo -e "${BLUE}📤 Using mutt to send email...${NC}"
    
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
    
    echo "$BODY" | mutt -s "$SUBJECT" "${ATTACHMENTS[@]}" -- "$TO"
    echo -e "${GREEN}✅ Email sent successfully using mutt${NC}"
    
elif command -v msmtp &> /dev/null; then
    echo -e "${BLUE}📤 Using msmtp to send email...${NC}"
    
    echo -e "${BLUE}📎 Attaching files:${NC}"
    if [ -d "$OUTPUT_DIR" ]; then
        for file in "$OUTPUT_DIR"/*; do
            [ -e "$file" ] || continue
            echo -e "${GREEN}   - $(basename "$file")${NC}"
        done
    fi
    
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
        echo "Content-Type: text/plain"
        echo
        echo "$BODY"
        
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
    
    msmtp --host="$SMTP_SERVER" --port="$SMTP_PORT" --auth=on --user="$SMTP_USER" --passwordeval="echo $SMTP_PASS" -f "$FROM_EMAIL" "$TO" < "$TMPMAIL"
    rm "$TMPMAIL"
    echo -e "${GREEN}✅ Email sent successfully using msmtp${NC}"
    
elif command -v mail &> /dev/null; then
    echo -e "${BLUE}📤 Using mail to send email...${NC}"
    # Note: macOS mail command has limited attachment support
    # For now, just send the email body without attachments
    echo "$BODY" | mail -s "$SUBJECT" "$TO"
    echo -e "${YELLOW}⚠️  Email sent without attachments (macOS mail limitation)${NC}"
    echo -e "${YELLOW}💡 Consider installing mutt or using Python for full attachment support${NC}"
    
else
    echo -e "${RED}❌ No email client found. Please install 'python3', 'mutt', 'msmtp', or 'mail' to send emails with attachments.${NC}"
    echo -e "${YELLOW}💡 Python3 is recommended for full attachment support${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Email with build outputs sent successfully!${NC}"
echo -e "${YELLOW}📧 Email sent to: $TO${NC}"
echo -e "${YELLOW}📧 Subject: $SUBJECT${NC}"
echo -e "${YELLOW}📧 Status: $BUILD_STATUS${NC}" 