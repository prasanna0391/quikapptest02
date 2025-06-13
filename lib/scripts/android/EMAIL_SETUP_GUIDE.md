# Email Notification Setup Guide

This guide will help you configure email notifications for build failures using free email services.

## Quick Setup

Run the automated setup script:

```bash
lib/scripts/android/setup_email_config.sh
```

This script will guide you through the configuration process and test your email settings.

## Manual Setup

If you prefer to configure manually, follow these steps:

### 1. Choose Your Email Service

#### Option A: Gmail (Recommended)

- **SMTP Server**: `smtp.gmail.com`
- **Port**: `587`
- **Security**: TLS/SSL
- **Authentication**: App Password required

**Setup Steps for Gmail:**

1. Enable 2-Step Verification in your Google Account
2. Go to Google Account → Security → 2-Step Verification → App passwords
3. Generate a new app password for "Mail"
4. Use this app password (not your regular password)

#### Option B: Outlook/Hotmail

- **SMTP Server**: `smtp-mail.outlook.com`
- **Port**: `587`
- **Security**: TLS/SSL
- **Authentication**: Regular password or app password

#### Option C: Yahoo Mail

- **SMTP Server**: `smtp.mail.yahoo.com`
- **Port**: `587`
- **Security**: TLS/SSL
- **Authentication**: App password required

#### Option D: ProtonMail

- **SMTP Server**: `smtp.protonmail.ch`
- **Port**: `587`
- **Security**: TLS/SSL
- **Authentication**: App password required

### 2. Update Configuration

Edit `lib/scripts/android/export.sh` and update these lines:

```bash
# --- Email Notification Configuration ---
export SMTP_SERVER="smtp.gmail.com"  # Replace with your SMTP server
export SMTP_USERNAME="your-email@gmail.com"  # Replace with your email
export SMTP_PASSWORD="your-app-password"  # Replace with your password/app password
```

### 3. Test Configuration

Run the test script:

```bash
lib/scripts/android/test_error_email.sh
```

## Troubleshooting

### Common Issues

#### 1. Gmail "Invalid Credentials" Error

**Problem**: Authentication failed
**Solution**:

- Make sure 2-Step Verification is enabled
- Use an App Password, not your regular password
- Generate a new App Password specifically for "Mail"

#### 2. "Connection Refused" Error

**Problem**: Cannot connect to SMTP server
**Solution**:

- Check your internet connection
- Verify SMTP server and port are correct
- Check if your network/firewall blocks SMTP traffic

#### 3. "Authentication Required" Error

**Problem**: SMTP server requires authentication
**Solution**:

- Ensure username and password are correct
- For Gmail, use App Password instead of regular password
- Check if your email service requires app-specific passwords

#### 4. "SSL/TLS Required" Error

**Problem**: Server requires secure connection
**Solution**:

- The script automatically uses SSL/TLS
- Make sure you're using the correct port (587 for TLS, 465 for SSL)

### Testing Your Configuration

1. **Manual Test with curl**:

```bash
curl -v --url "smtp://smtp.gmail.com:587" \
  --mail-from "build@quikapp.co" \
  --mail-rcpt "your-email@gmail.com" \
  --user "your-email@gmail.com:your-app-password" \
  --upload-file <(echo "Subject: Test
From: build@quikapp.co
To: your-email@gmail.com

Test email body") \
  --ssl-reqd
```

2. **Check Email Logs**:
   If email sending fails, check the generated HTML files in your project root:

```bash
ls -la build_error_email_*.html
```

## Security Best Practices

1. **Use App Passwords**: Never use your main account password
2. **Environment Variables**: Store sensitive data in environment variables
3. **Regular Updates**: Update app passwords regularly
4. **Limited Scope**: Use email accounts dedicated to build notifications

## Alternative Email Services

### Free SMTP Services

1. **SendGrid** (Free tier: 100 emails/day)

   - SMTP: `smtp.sendgrid.net:587`
   - Requires API key

2. **Mailgun** (Free tier: 5,000 emails/month)

   - SMTP: `smtp.mailgun.org:587`
   - Requires API key

3. **Amazon SES** (Free tier: 62,000 emails/month)
   - SMTP: `email-smtp.us-east-1.amazonaws.com:587`
   - Requires AWS account and credentials

### Self-Hosted Options

1. **Postfix** with Gmail relay
2. **Mail-in-a-Box**
3. **iRedMail**

## Configuration Examples

### Gmail Configuration

```bash
export SMTP_SERVER="smtp.gmail.com"
export SMTP_USERNAME="your-email@gmail.com"
export SMTP_PASSWORD="abcd efgh ijkl mnop"  # App Password
```

### Outlook Configuration

```bash
export SMTP_SERVER="smtp-mail.outlook.com"
export SMTP_USERNAME="your-email@outlook.com"
export SMTP_PASSWORD="your-password"
```

### Yahoo Configuration

```bash
export SMTP_SERVER="smtp.mail.yahoo.com"
export SMTP_USERNAME="your-email@yahoo.com"
export SMTP_PASSWORD="your-app-password"
```

## Email Content

The system sends professional HTML emails with:

- **Error Summary**: Brief description of the build failure
- **Error Details**: Full error logs and stack traces
- **Resolution Steps**: Specific steps to fix the issue
- **Build Information**: Project details, version, and timestamp

## Monitoring and Maintenance

1. **Regular Testing**: Test email configuration monthly
2. **Log Monitoring**: Check for email sending failures
3. **Password Rotation**: Update app passwords regularly
4. **Backup Configuration**: Keep backup of working configurations

## Support

If you encounter issues:

1. Check the troubleshooting section above
2. Review the generated HTML email files
3. Test with the setup script
4. Check your email service's SMTP documentation
5. Contact your email service provider for SMTP issues

## Files

- `setup_email_config.sh` - Automated configuration script
- `export.sh` - Configuration file
- `send_error_email.sh` - Email sending script
- `test_error_email.sh` - Test script
- `EMAIL_SETUP_GUIDE.md` - This guide
