#!/bin/bash

# Email Configuration for QuikApp Build System
# This file contains email settings used across all workflows and notifications
# Priority: API configuration > Environment variables > Default values below

# =============================================================================
# SMTP CONFIGURATION
# =============================================================================
# These values can be overridden by API calls or environment variables
# For now, using default values until database/API is ready

# Default Email Configuration (can be overridden by API)
DEFAULT_SMTP_SERVER="smtp.gmail.com"
DEFAULT_SMTP_PORT="587"
DEFAULT_SMTP_USER="prasannasrie@gmail.com"
DEFAULT_SMTP_PASS="jbbf nzhm zoay lbwb"

# QuikApp Branding Email Settings
DEFAULT_FROM_EMAIL="no-reply@quikapp.co"
DEFAULT_REPLY_TO="support@quikapp.co"

# =============================================================================
# EMAIL CONFIGURATION PRIORITY SYSTEM
# =============================================================================
# Priority Order:
# 1. API provided configuration (when database is ready)
# 2. Environment variables
# 3. Default values above

# SMTP Server Configuration
if [ -n "$API_SMTP_SERVER" ]; then
    SMTP_SERVER="$API_SMTP_SERVER"
elif [ -n "$SMTP_SERVER" ]; then
    SMTP_SERVER="$SMTP_SERVER"
else
    SMTP_SERVER="$DEFAULT_SMTP_SERVER"
fi

# SMTP Port Configuration
if [ -n "$API_SMTP_PORT" ]; then
    SMTP_PORT="$API_SMTP_PORT"
elif [ -n "$SMTP_PORT" ]; then
    SMTP_PORT="$SMTP_PORT"
else
    SMTP_PORT="$DEFAULT_SMTP_PORT"
fi

# SMTP Username Configuration
if [ -n "$API_SMTP_USER" ]; then
    SMTP_USER="$API_SMTP_USER"
elif [ -n "$SMTP_USERNAME" ]; then
    SMTP_USER="$SMTP_USERNAME"
else
    SMTP_USER="$DEFAULT_SMTP_USER"
fi

# SMTP Password Configuration
if [ -n "$API_SMTP_PASS" ]; then
    SMTP_PASS="$API_SMTP_PASS"
elif [ -n "$SMTP_PASSWORD" ]; then
    SMTP_PASS="$SMTP_PASSWORD"
else
    SMTP_PASS="$DEFAULT_SMTP_PASS"
fi

# From Email Configuration
if [ -n "$API_FROM_EMAIL" ]; then
    FROM_EMAIL="$API_FROM_EMAIL"
elif [ -n "$FROM_EMAIL" ]; then
    FROM_EMAIL="$FROM_EMAIL"
else
    FROM_EMAIL="$DEFAULT_FROM_EMAIL"
fi

# Reply-To Email Configuration
if [ -n "$API_REPLY_TO" ]; then
    REPLY_TO="$API_REPLY_TO"
elif [ -n "$REPLY_TO" ]; then
    REPLY_TO="$REPLY_TO"
else
    REPLY_TO="$DEFAULT_REPLY_TO"
fi

# =============================================================================
# EXPORT EMAIL CONFIGURATION VARIABLES
# =============================================================================
# Export all email configuration variables for use in other scripts

export SMTP_SERVER
export SMTP_PORT
export SMTP_USER
export SMTP_PASS
export FROM_EMAIL
export REPLY_TO

# =============================================================================
# EMAIL CONFIGURATION VALIDATION
# =============================================================================
validate_email_config() {
    local errors=0
    
    echo "🔍 Validating email configuration..."
    
    # Check required variables
    if [ -z "$SMTP_SERVER" ]; then
        echo "❌ SMTP_SERVER is not set"
        errors=$((errors + 1))
    fi
    
    if [ -z "$SMTP_PORT" ]; then
        echo "❌ SMTP_PORT is not set"
        errors=$((errors + 1))
    fi
    
    if [ -z "$SMTP_USER" ]; then
        echo "❌ SMTP_USER is not set"
        errors=$((errors + 1))
    fi
    
    if [ -z "$SMTP_PASS" ]; then
        echo "❌ SMTP_PASS is not set"
        errors=$((errors + 1))
    fi
    
    if [ -z "$FROM_EMAIL" ]; then
        echo "❌ FROM_EMAIL is not set"
        errors=$((errors + 1))
    fi
    
    # Validate SMTP port is numeric
    if ! [[ "$SMTP_PORT" =~ ^[0-9]+$ ]]; then
        echo "❌ SMTP_PORT must be numeric: $SMTP_PORT"
        errors=$((errors + 1))
    fi
    
    # Validate email format (basic check)
    if [[ ! "$FROM_EMAIL" =~ ^[^@]+@[^@]+\.[^@]+$ ]]; then
        echo "❌ FROM_EMAIL format is invalid: $FROM_EMAIL"
        errors=$((errors + 1))
    fi
    
    if [[ ! "$SMTP_USER" =~ ^[^@]+@[^@]+\.[^@]+$ ]]; then
        echo "❌ SMTP_USER format is invalid: $SMTP_USER"
        errors=$((errors + 1))
    fi
    
    if [ $errors -eq 0 ]; then
        echo "✅ Email configuration is valid"
        return 0
    else
        echo "❌ Email configuration has $errors error(s)"
        return 1
    fi
}

# =============================================================================
# EMAIL CONFIGURATION DEBUG INFO
# =============================================================================
debug_email_config() {
    echo "📧 Email Configuration Debug Info:"
    echo "=================================="
    echo "SMTP Server: $SMTP_SERVER"
    echo "SMTP Port: $SMTP_PORT"
    echo "SMTP User: $SMTP_USER"
    echo "SMTP Pass: [REDACTED]"
    echo "From Email: $FROM_EMAIL"
    echo "Reply-To: $REPLY_TO"
    echo "=================================="
}

# =============================================================================
# EMAIL CONFIGURATION FOR PYTHON SCRIPTS
# =============================================================================
# Create environment variables that Python scripts can use
export EMAIL_SMTP_SERVER="$SMTP_SERVER"
export EMAIL_SMTP_PORT="$SMTP_PORT"
export EMAIL_SMTP_USER="$SMTP_USER"
export EMAIL_SMTP_PASS="$SMTP_PASS"
export EMAIL_FROM="$FROM_EMAIL"
export EMAIL_REPLY_TO="$REPLY_TO"

# =============================================================================
# USAGE FUNCTIONS
# =============================================================================
# Function to source this configuration in other scripts
load_email_config() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local config_file="$script_dir/email_config.sh"
    
    if [ -f "$config_file" ]; then
        source "$config_file"
        echo "✅ Email configuration loaded from $config_file"
    else
        echo "❌ Email configuration file not found: $config_file"
        return 1
    fi
}

# Function to get email configuration as JSON (for API integration)
get_email_config_json() {
    cat << EOF
{
    "smtp_server": "$SMTP_SERVER",
    "smtp_port": "$SMTP_PORT",
    "smtp_user": "$SMTP_USER",
    "smtp_pass": "[REDACTED]",
    "from_email": "$FROM_EMAIL",
    "reply_to": "$REPLY_TO"
}
EOF
}

# =============================================================================
# AUTO-EXECUTION
# =============================================================================
# When this script is sourced, automatically validate configuration
if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
    # Script is being sourced
    echo "📧 Loading QuikApp email configuration..."
    if validate_email_config; then
        echo "✅ Email configuration loaded successfully"
    else
        echo "⚠️  Email configuration loaded with errors"
    fi
fi 