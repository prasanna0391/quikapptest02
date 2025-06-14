# QuikApp Email Configuration System

This document explains the centralized email configuration system for the QuikApp build system.

## Overview

The email configuration is centralized in `lib/scripts/email_config.sh` to provide consistent email settings across all workflows and notifications.

## Configuration Priority

The system uses a priority-based configuration system:

1. **API Configuration** (when database is ready)

   - `API_SMTP_SERVER`
   - `API_SMTP_PORT`
   - `API_SMTP_USER`
   - `API_SMTP_PASS`
   - `API_FROM_EMAIL`
   - `API_REPLY_TO`

2. **Environment Variables**

   - `SMTP_SERVER`
   - `SMTP_PORT`
   - `SMTP_USERNAME` / `SMTP_USER`
   - `SMTP_PASSWORD` / `SMTP_PASS`
   - `FROM_EMAIL`
   - `REPLY_TO`

3. **Default Values** (current configuration)
   ```bash
   DEFAULT_SMTP_SERVER="smtp.gmail.com"
   DEFAULT_SMTP_PORT="587"
   DEFAULT_SMTP_USER="prasannasrie@gmail.com"
   DEFAULT_SMTP_PASS="jbbf nzhm zoay lbwb"
   DEFAULT_FROM_EMAIL="no-reply@quikapp.co"
   DEFAULT_REPLY_TO="support@quikapp.co"
   ```

## Files Using Email Configuration

### Shell Scripts

- `lib/scripts/android/send_output_email.sh` - Android build notifications
- All workflow success notification steps in `codemagic.yaml`

### Python Scripts

- `lib/scripts/email_notification.py` - Main email notification system
- `lib/scripts/android/send_output_email.py` - Python email sender

## Usage in Scripts

### Shell Scripts

```bash
# Load email configuration
source lib/scripts/email_config.sh

# Use the configured variables
echo "Sending email via $SMTP_SERVER:$SMTP_PORT"
echo "From: $FROM_EMAIL"
echo "To: $TO_EMAIL"
```

### Python Scripts

```python
# Read from environment variables (set by email_config.sh)
smtp_server = os.environ.get("EMAIL_SMTP_SERVER", "smtp.gmail.com")
smtp_user = os.environ.get("EMAIL_SMTP_USER", "user@example.com")
from_email = os.environ.get("EMAIL_FROM", "no-reply@quikapp.co")
```

## Available Functions

### `validate_email_config()`

Validates all email configuration variables and checks for proper format.

### `debug_email_config()`

Displays current email configuration (passwords redacted).

### `get_email_config_json()`

Returns email configuration as JSON format for API integration.

### `load_email_config()`

Helper function to load configuration in other scripts.

## Environment Variables Exported

The configuration file exports these variables for use in all scripts:

**For Shell Scripts:**

- `SMTP_SERVER`
- `SMTP_PORT`
- `SMTP_USER`
- `SMTP_PASS`
- `FROM_EMAIL`
- `REPLY_TO`

**For Python Scripts:**

- `EMAIL_SMTP_SERVER`
- `EMAIL_SMTP_PORT`
- `EMAIL_SMTP_USER`
- `EMAIL_SMTP_PASS`
- `EMAIL_FROM`
- `EMAIL_REPLY_TO`

## API Integration (Future)

When the database is ready, the API can override any configuration by setting the `API_*` environment variables:

```bash
export API_SMTP_SERVER="api-provided-server.com"
export API_SMTP_USER="api-user@domain.com"
export API_SMTP_PASS="api-generated-password"
```

## Security Notes

- Passwords are redacted in debug output
- Configuration validation checks email format
- Fallback values ensure system continues working if configuration fails

## Testing Email Configuration

```bash
# Load and test configuration
source lib/scripts/email_config.sh

# Validate configuration
validate_email_config

# Debug current settings
debug_email_config

# Get JSON format
get_email_config_json
```

## Future Enhancements

1. **Database Integration**: Connect to QuikApp database for dynamic configuration
2. **API Endpoints**: RESTful API for email configuration management
3. **Email Templates**: Dynamic template selection based on configuration
4. **Multiple SMTP Providers**: Support for different email providers per project
5. **Email Queuing**: Queue system for high-volume email sending

## Troubleshooting

### Configuration Not Loading

- Check if `lib/scripts/email_config.sh` exists
- Verify file permissions (should be executable)
- Check for syntax errors in the configuration file

### Email Sending Failures

- Run `validate_email_config()` to check configuration
- Verify SMTP credentials are correct
- Check network connectivity to SMTP server
- Review email provider specific requirements (app passwords, etc.)

### Environment Variable Issues

- Ensure proper sourcing of configuration file
- Check variable names match expected format
- Verify API variables take precedence when set

---

**Last Updated**: 2024
**Version**: 1.0  
**Contact**: support@quikapp.co
