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

# Source environment variables to get EMAIL_ID
if [ -f "$SCRIPT_DIR/export.sh" ]; then
    source "$SCRIPT_DIR/export.sh"
fi

# --- CONFIGURE THESE VARIABLES ---
TO="${EMAIL_ID:-prasannasrie@gmail.com}"
FROM="no-reply@quikapp.co"
SUBJECT="Android Build Report - $(date '+%Y-%m-%d %H:%M:%S')"

# Determine build status
if [ -f "$OUTPUT_DIR/app-release.apk" ] || [ -f "$OUTPUT_DIR/app-release.aab" ]; then
    BUILD_STATUS="✅ SUCCESS"
    STATUS_COLOR="SUCCESS"
    BODY="Android build completed successfully!

Build completed at: $(date '+%Y-%m-%d %H:%M:%S')
Project: ${APP_NAME:-Garbcode App}
Package: ${PKG_NAME:-com.garbcode.garbcodeapp}
Version: ${VERSION_NAME:-1.0.22}
Build Status: SUCCESS

Build artifacts are attached to this email.

Best regards,
QuikApp Build System"
else
    BUILD_STATUS="❌ FAILED"
    STATUS_COLOR="FAILED"
    BODY="Android build failed!

Build attempted at: $(date '+%Y-%m-%d %H:%M:%S')
Project: ${APP_NAME:-Garbcode App}
Package: ${PKG_NAME:-com.garbcode.garbcodeapp}
Version: ${VERSION_NAME:-1.0.22}
Build Status: FAILED

Reason: Build artifacts not found. Please check the build logs for more details.

Best regards,
QuikApp Build System"
fi

# Email configuration - Update these with your actual settings
SMTP_SERVER="smtp.gmail.com"
SMTP_PORT="587"
SMTP_USER="your-email@gmail.com"
SMTP_PASS="your-app-password"
# ---------------------------------

echo -e "${BLUE}📧 Sending email with build outputs...${NC}"
echo -e "${BLUE}📧 To: $TO${NC}"
echo -e "${BLUE}📧 From: $FROM${NC}"
echo -e "${BLUE}📧 Status: $BUILD_STATUS${NC}"

# Check if output directory exists and has files
if [ ! -d "$OUTPUT_DIR" ]; then
    echo -e "${RED}❌ Output directory not found: $OUTPUT_DIR${NC}"
    # Send failure email even if no output directory
    BODY="Android build failed!

Build attempted at: $(date '+%Y-%m-%d %H:%M:%S')
Project: ${APP_NAME:-Garbcode App}
Package: ${PKG_NAME:-com.garbcode.garbcodeapp}
Version: ${VERSION_NAME:-1.0.22}
Build Status: FAILED

Reason: Output directory not found. Build process may have failed early.

Best regards,
QuikApp Build System"
fi

# Check for files in output directory
if [ -z "$(ls -A "$OUTPUT_DIR" 2>/dev/null)" ]; then
    echo -e "${YELLOW}⚠️  No files found in output directory${NC}"
    # Update body for no files case
    BODY="Android build completed but no artifacts found!

Build completed at: $(date '+%Y-%m-%d %H:%M:%S')
Project: ${APP_NAME:-Garbcode App}
Package: ${PKG_NAME:-com.garbcode.garbcodeapp}
Version: ${VERSION_NAME:-1.0.22}
Build Status: WARNING

Reason: Build completed but no APK or AAB files were generated. Please check the build configuration.

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
        echo "From: $FROM"
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
    
    msmtp --host="$SMTP_SERVER" --port="$SMTP_PORT" --auth=on --user="$SMTP_USER" --passwordeval="echo $SMTP_PASS" -f "$FROM" "$TO" < "$TMPMAIL"
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