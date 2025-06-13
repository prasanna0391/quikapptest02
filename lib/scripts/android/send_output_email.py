#!/usr/bin/env python3

"""
Send Output Email Script (Python Version)
This script sends an email with all files in the output folder as attachments
"""

import os
import sys
import smtplib
import base64
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.base import MIMEBase
from email import encoders
from datetime import datetime
from pathlib import Path

# Colors for output
class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    NC = '\033[0m'  # No Color

def print_colored(color, message):
    print(f"{color}{message}{Colors.NC}")

# Read configuration from environment variables
TO_EMAIL = os.environ.get("EMAIL_ID", "recipient@example.com")
FROM_EMAIL = "no-reply@quikapp.co"
SMTP_SERVER = os.environ.get("SMTP_SERVER", "smtp.gmail.com")
SMTP_PORT = int(os.environ.get("SMTP_PORT", "587"))
SMTP_USER = os.environ.get("SMTP_USERNAME", "your-email@gmail.com")
SMTP_PASS = os.environ.get("SMTP_PASSWORD", "your-app-password")

# Get app details from environment variables
APP_NAME = os.environ.get("APP_NAME", "Garbcode App")
PKG_NAME = os.environ.get("PKG_NAME", "com.garbcode.garbcodeapp")
VERSION_NAME = os.environ.get("VERSION_NAME", "1.0.22")

# Gmail attachment size limit (25MB)
GMAIL_SIZE_LIMIT = 25 * 1024 * 1024  # 25MB in bytes

def get_file_size_mb(file_path):
    """Get file size in MB"""
    return os.path.getsize(file_path) / (1024 * 1024)

def main():
    # Get the script directory and project root
    script_dir = Path(__file__).parent.absolute()
    project_root = script_dir.parent.parent.parent
    output_dir = project_root / "output"
    
    print_colored(Colors.BLUE, "📧 Sending email with build outputs...")
    
    # Check if output directory exists and has files
    if not output_dir.exists():
        print_colored(Colors.RED, f"❌ Output directory not found: {output_dir}")
        sys.exit(1)
    
    # Check for files in output directory
    files = list(output_dir.glob("*"))
    if not files:
        print_colored(Colors.YELLOW, "⚠️  No files found in output directory")
        sys.exit(1)
    
    # Create email
    msg = MIMEMultipart()
    msg['From'] = FROM_EMAIL
    msg['To'] = TO_EMAIL
    msg['Subject'] = f"Android Build Outputs - {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"
    
    # Check file sizes and prepare email content
    large_files = []
    small_files = []
    total_size = 0
    
    for file_path in files:
        if file_path.is_file():
            file_size = os.path.getsize(file_path)
            total_size += file_size
            
            if file_size > GMAIL_SIZE_LIMIT:
                large_files.append((file_path, file_size))
            else:
                small_files.append((file_path, file_size))
    
    # Email body
    body = f"""Android build completed successfully!

Build completed at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
Project: {APP_NAME}
Package: {PKG_NAME}
Version: {VERSION_NAME}
Build Status: ✅ SUCCESS

Build artifacts are attached to this email.

Best regards,
QuikApp Build System"""
    
    # If we have large files, modify the email body
    if large_files:
        body += "\n\n⚠️  NOTE: Some files were too large to attach via email:\n"
        for file_path, file_size in large_files:
            size_mb = file_size / (1024 * 1024)
            body += f"   - {file_path.name} ({size_mb:.1f} MB)\n"
        body += "\nThese files are available in your project's output directory."
    
    msg.attach(MIMEText(body, 'plain'))
    
    # Attach only small files
    print_colored(Colors.BLUE, "📎 Attaching files:")
    for file_path, file_size in small_files:
        size_mb = file_size / (1024 * 1024)
        print_colored(Colors.GREEN, f"   - {file_path.name} ({size_mb:.1f} MB)")
        
        # Create attachment
        with open(file_path, "rb") as attachment:
            part = MIMEBase('application', 'octet-stream')
            part.set_payload(attachment.read())
        
        # Encode attachment
        encoders.encode_base64(part)
        part.add_header(
            'Content-Disposition',
            f'attachment; filename= {file_path.name}'
        )
        
        msg.attach(part)
    
    # Show large files that couldn't be attached
    if large_files:
        print_colored(Colors.YELLOW, "⚠️  Files too large for email attachment:")
        for file_path, file_size in large_files:
            size_mb = file_size / (1024 * 1024)
            print_colored(Colors.YELLOW, f"   - {file_path.name} ({size_mb:.1f} MB)")
    
    # Send email
    try:
        print_colored(Colors.BLUE, "📤 Sending email...")
        server = smtplib.SMTP(SMTP_SERVER, SMTP_PORT)
        server.starttls()
        server.login(SMTP_USER, SMTP_PASS)
        text = msg.as_string()
        server.sendmail(FROM_EMAIL, TO_EMAIL, text)
        server.quit()
        
        print_colored(Colors.GREEN, "✅ Email sent successfully!")
        print_colored(Colors.YELLOW, f"📧 Email sent to: {TO_EMAIL}")
        print_colored(Colors.YELLOW, f"📧 Subject: {msg['Subject']}")
        
        if large_files:
            print_colored(Colors.YELLOW, "💡 Large files are available in the output directory")
        
    except Exception as e:
        print_colored(Colors.RED, f"❌ Failed to send email: {str(e)}")
        print_colored(Colors.YELLOW, "💡 Please check your SMTP configuration in export.sh")
        sys.exit(1)

if __name__ == "__main__":
    main() 