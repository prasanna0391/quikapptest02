#!/bin/bash

# Email Configuration Setup Script
# This script helps configure email notifications for build failures

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}📧 Email Configuration Setup${NC}"
echo "=================================="
echo ""

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXPORT_FILE="$SCRIPT_DIR/export.sh"

echo -e "${BLUE}🔧 This script will help you configure email notifications for build failures${NC}"
echo ""

# Check if export.sh exists
if [ ! -f "$EXPORT_FILE" ]; then
    echo -e "${RED}❌ export.sh file not found at: $EXPORT_FILE${NC}"
    exit 1
fi

echo -e "${YELLOW}📋 Available free email services:${NC}"
echo "1. Gmail (smtp.gmail.com:587)"
echo "2. Outlook/Hotmail (smtp-mail.outlook.com:587)"
echo "3. Yahoo Mail (smtp.mail.yahoo.com:587)"
echo "4. ProtonMail (smtp.protonmail.ch:587)"
echo "5. Custom SMTP server"
echo ""

read -p "Choose your email service (1-5): " choice

case $choice in
    1)
        SMTP_SERVER="smtp.gmail.com"
        SMTP_PORT="587"
        SERVICE_NAME="Gmail"
        ;;
    2)
        SMTP_SERVER="smtp-mail.outlook.com"
        SMTP_PORT="587"
        SERVICE_NAME="Outlook/Hotmail"
        ;;
    3)
        SMTP_SERVER="smtp.mail.yahoo.com"
        SMTP_PORT="587"
        SERVICE_NAME="Yahoo Mail"
        ;;
    4)
        SMTP_SERVER="smtp.protonmail.ch"
        SMTP_PORT="587"
        SERVICE_NAME="ProtonMail"
        ;;
    5)
        read -p "Enter SMTP server (e.g., smtp.gmail.com): " SMTP_SERVER
        read -p "Enter SMTP port (default: 587): " SMTP_PORT
        SMTP_PORT=${SMTP_PORT:-587}
        SERVICE_NAME="Custom"
        ;;
    *)
        echo -e "${RED}❌ Invalid choice${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${BLUE}📧 Email Configuration for $SERVICE_NAME${NC}"
echo ""

read -p "Enter your email address: " EMAIL_USERNAME
read -s -p "Enter your password or app password: " EMAIL_PASSWORD
echo ""

# Validate email format
if [[ ! "$EMAIL_USERNAME" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
    echo -e "${RED}❌ Invalid email format${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}💡 Important Notes:${NC}"
echo "• For Gmail: You need to use an App Password, not your regular password"
echo "• To generate a Gmail App Password:"
echo "  1. Go to Google Account settings"
echo "  2. Security > 2-Step Verification > App passwords"
echo "  3. Generate a new app password for 'Mail'"
echo "• For other services: Use your regular password or app-specific password"
echo ""

read -p "Do you want to test the email configuration? (y/n): " test_email

# Update export.sh file
echo ""
echo -e "${BLUE}🔧 Updating export.sh configuration...${NC}"

# Create backup
cp "$EXPORT_FILE" "$EXPORT_FILE.backup.$(date +%Y%m%d_%H%M%S)"

# Update the email configuration section
sed -i.tmp '/^# --- Email Notification Configuration ---/,/^# --- Keystore Credentials/ {
    /^export SMTP_SERVER=/d
    /^export SMTP_USERNAME=/d
    /^export SMTP_PASSWORD=/d
    /^# export SMTP_SERVER=/d
    /^# export SMTP_USERNAME=/d
    /^# export SMTP_PASSWORD=/d
}' "$EXPORT_FILE"

# Add new configuration
sed -i.tmp "/^# --- Email Notification Configuration ---/a\\
export SMTP_SERVER=\"$SMTP_SERVER\"\\
export SMTP_USERNAME=\"$EMAIL_USERNAME\"\\
export SMTP_PASSWORD=\"$EMAIL_PASSWORD\"\\
" "$EXPORT_FILE"

# Clean up temporary file
rm -f "$EXPORT_FILE.tmp"

echo -e "${GREEN}✅ Email configuration updated in export.sh${NC}"
echo -e "${GREEN}✅ Backup created: $EXPORT_FILE.backup.$(date +%Y%m%d_%H%M%S)${NC}"

# Test email configuration
if [[ "$test_email" =~ ^[Yy]$ ]]; then
    echo ""
    echo -e "${BLUE}🧪 Testing email configuration...${NC}"
    
    # Source the updated configuration
    . "$EXPORT_FILE"
    
    # Test email sending
    if [ -n "${SMTP_SERVER:-}" ] && [ -n "${SMTP_USERNAME:-}" ] && [ -n "${SMTP_PASSWORD:-}" ]; then
        echo -e "${BLUE}📧 Sending test email to: $EMAIL_ID${NC}"
        
        # Create a simple test email
        TEST_SUBJECT="Test Email - Build Notification System"
        TEST_BODY="This is a test email from the QuikApp build notification system.

Email Configuration:
- SMTP Server: $SMTP_SERVER
- Username: $EMAIL_USERNAME
- Service: $SERVICE_NAME

If you receive this email, your configuration is working correctly!

Best regards,
QuikApp Build System"

        # Try to send test email using curl
        if command -v curl >/dev/null 2>&1; then
            echo -e "${BLUE}📤 Attempting to send test email...${NC}"
            
            # Create email content
            EMAIL_CONTENT=$(cat << EOF
From: build@quikapp.co
To: $EMAIL_ID
Subject: $TEST_SUBJECT
MIME-Version: 1.0
Content-Type: text/plain; charset=UTF-8

$TEST_BODY
EOF
)
            
            if curl -s --url "smtp://${SMTP_SERVER}:${SMTP_PORT}" \
                --mail-from "build@quikapp.co" \
                --mail-rcpt "$EMAIL_ID" \
                --user "${EMAIL_USERNAME}:${EMAIL_PASSWORD}" \
                --upload-file <(echo "$EMAIL_CONTENT") \
                --ssl-reqd; then
                echo -e "${GREEN}✅ Test email sent successfully!${NC}"
                echo -e "${GREEN}📧 Check your inbox for the test email${NC}"
            else
                echo -e "${YELLOW}⚠️  Test email sending failed${NC}"
                echo -e "${YELLOW}💡 This might be due to:${NC}"
                echo -e "${YELLOW}   • Incorrect password/app password${NC}"
                echo -e "${YELLOW}   • 2FA not enabled (for Gmail)${NC}"
                echo -e "${YELLOW}   • SMTP settings not configured correctly${NC}"
                echo -e "${YELLOW}   • Network/firewall restrictions${NC}"
            fi
        else
            echo -e "${YELLOW}⚠️  curl not found - cannot test email sending${NC}"
            echo -e "${YELLOW}💡 Install curl to test email functionality${NC}"
        fi
    else
        echo -e "${RED}❌ Email configuration incomplete${NC}"
    fi
fi

echo ""
echo -e "${GREEN}🎉 Email configuration setup completed!${NC}"
echo ""
echo -e "${BLUE}📋 Configuration Summary:${NC}"
echo "• SMTP Server: $SMTP_SERVER"
echo "• SMTP Port: $SMTP_PORT"
echo "• Username: $EMAIL_USERNAME"
echo "• Service: $SERVICE_NAME"
echo "• Recipient: $EMAIL_ID"
echo ""
echo -e "${YELLOW}💡 Next steps:${NC}"
echo "1. If using Gmail, make sure to enable 2FA and generate an App Password"
echo "2. Test the configuration by running a build that fails"
echo "3. Check your email for build failure notifications"
echo ""
echo -e "${BLUE}📄 Configuration file: $EXPORT_FILE${NC}" 