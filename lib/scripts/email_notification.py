#!/usr/bin/env python3

"""
Comprehensive Email Notification System for QuikApp Build System
Supports both success and error notifications with beautiful HTML templates
"""

import os
import sys
import smtplib
import json
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
    PURPLE = '\033[0;35m'
    CYAN = '\033[0;36m'
    NC = '\033[0m'  # No Color

def print_colored(color, message):
    print(f"{color}{message}{Colors.NC}")

class EmailNotificationSystem:
    def __init__(self):
        self.script_dir = Path(__file__).parent.absolute()
        self.project_root = self.script_dir.parent.parent.parent
        self.templates_dir = self.script_dir / "email_templates"
        
        # QuikApp Details
        self.quikapp_website = os.environ.get("QUIKAPP_WEBSITE", "https://quikapp.co")
        self.quikapp_dashboard = os.environ.get("QUIKAPP_DASHBOARD", "https://app.quikapp.co")
        self.quikapp_docs = os.environ.get("QUIKAPP_DOCS", "https://docs.quikapp.co")
        self.quikapp_support = os.environ.get("QUIKAPP_SUPPORT", "support@quikapp.co")
        
        # Email configuration
        self.to_email = os.environ.get("EMAIL_ID", "prasannasrie@gmail.com")
        self.from_email = os.environ.get("EMAIL_FROM", "prasannasrie@gmail.com")
        self.from_name = os.environ.get("EMAIL_FROM_NAME", "QuikApp Build System")
        self.cc_email = os.environ.get("EMAIL_CC", "")
        self.bcc_email = os.environ.get("EMAIL_BCC", "")
        self.smtp_server = os.environ.get("EMAIL_SMTP_SERVER", "smtp.gmail.com")
        self.smtp_port = int(os.environ.get("EMAIL_SMTP_PORT", "587"))
        self.smtp_user = os.environ.get("EMAIL_SMTP_USER", "prasannasrie@gmail.com")
        self.smtp_pass = os.environ.get("EMAIL_SMTP_PASS", "jbbf nzhm zoay lbwb")
        
        # App details from environment
        self.app_name = os.environ.get("APP_NAME", "QuikApp Project")
        self.pkg_name = os.environ.get("PKG_NAME", "com.quikapp.project")
        self.bundle_id = os.environ.get("BUNDLE_ID", "com.quikapp.project")
        self.version_name = os.environ.get("VERSION_NAME", "1.0.0")
        self.version_code = os.environ.get("VERSION_CODE", "1")
        self.workflow_name = os.environ.get("WORKFLOW_NAME", "QuikApp Build")
        
        # Build details
        self.build_time = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        self.build_id = datetime.now().strftime('%Y%m%d_%H%M%S')

    def load_template(self, template_name):
        """Load HTML template and replace placeholders"""
        template_path = self.templates_dir / f"{template_name}.html"
        
        if not template_path.exists():
            print_colored(Colors.RED, f"❌ Template not found: {template_path}")
            return None
        
        with open(template_path, 'r', encoding='utf-8') as f:
            template_content = f.read()
        
        return template_content

    def replace_template_variables(self, template_content, variables):
        """Replace template variables with actual values"""
        for key, value in variables.items():
            placeholder = f"{{{{{key}}}}}"
            template_content = template_content.replace(placeholder, str(value))
        
        return template_content

    def get_artifacts_list(self, output_dir):
        """Generate HTML list of build artifacts"""
        if not output_dir.exists():
            return "<li>No artifacts found</li>"
        
        artifacts_html = ""
        files = list(output_dir.glob("*"))
        
        for file_path in files:
            if file_path.is_file():
                size_mb = os.path.getsize(file_path) / (1024 * 1024)
                
                # Determine icon based on file extension
                icon = "📄"
                if file_path.suffix.lower() == '.apk':
                    icon = "📱"
                elif file_path.suffix.lower() == '.aab':
                    icon = "📦"
                elif file_path.suffix.lower() == '.ipa':
                    icon = "🍎"
                elif file_path.suffix.lower() == '.zip':
                    icon = "🗜️"
                
                artifacts_html += f'<li class="artifact-item"><span class="artifact-icon">{icon}</span><span class="artifact-name">{file_path.name}</span><span class="artifact-size">({size_mb:.1f} MB)</span></li>'
        
        return artifacts_html if artifacts_html else "<li>No artifacts found</li>"

    def send_success_email(self):
        """Send success notification email"""
        print_colored(Colors.BLUE, "📧 Preparing success notification email...")
        
        # Load success template
        template_content = self.load_template("success_email")
        if not template_content:
            return False
        
        # Get artifacts list
        output_dir = self.project_root / "output"
        artifacts_list = self.get_artifacts_list(output_dir)
        
        # Prepare template variables
        variables = {
            "APP_NAME": self.app_name,
            "PKG_NAME": self.pkg_name,
            "BUNDLE_ID": self.bundle_id,
            "VERSION_NAME": self.version_name,
            "VERSION_CODE": self.version_code,
            "WORKFLOW_NAME": self.workflow_name,
            "BUILD_TIME": self.build_time,
            "BUILD_ID": self.build_id,
            "RECIPIENT_NAME": self.to_email.split('@')[0].replace('.', ' ').title(),
            "ARTIFACTS_LIST": artifacts_list,
            "QUIKAPP_WEBSITE": self.quikapp_website,
            "QUIKAPP_DASHBOARD": self.quikapp_dashboard,
            "QUIKAPP_DOCS": self.quikapp_docs,
            "QUIKAPP_SUPPORT": self.quikapp_support
        }
        
        # Replace template variables
        html_content = self.replace_template_variables(template_content, variables)
        
        # Create email
        msg = MIMEMultipart('alternative')
        msg['From'] = f"{self.from_name} <{self.from_email}>"
        msg['To'] = self.to_email
        msg['Subject'] = f"✅ QuikApp Build Successful - {self.app_name} ({self.workflow_name})"
        
        if self.cc_email:
            msg['Cc'] = self.cc_email
        
        if self.bcc_email:
            msg['Bcc'] = self.bcc_email
        
        # Attach HTML content
        html_part = MIMEText(html_content, 'html')
        msg.attach(html_part)
        
        return self.send_email(msg)

    def send_error_email(self, error_message, error_details):
        """Send error notification email"""
        print_colored(Colors.BLUE, "📧 Preparing error notification email...")
        
        # Load error template
        template_content = self.load_template("error_email")
        if not template_content:
            return False
        
        # Prepare template variables
        variables = {
            "APP_NAME": self.app_name,
            "PKG_NAME": self.pkg_name,
            "BUNDLE_ID": self.bundle_id,
            "VERSION_NAME": self.version_name,
            "VERSION_CODE": self.version_code,
            "WORKFLOW_NAME": self.workflow_name,
            "BUILD_TIME": self.build_time,
            "BUILD_ID": self.build_id,
            "RECIPIENT_NAME": self.to_email.split('@')[0].replace('.', ' ').title(),
            "ERROR_MESSAGE": error_message,
            "ERROR_DETAILS": error_details,
            "QUIKAPP_WEBSITE": self.quikapp_website,
            "QUIKAPP_DASHBOARD": self.quikapp_dashboard,
            "QUIKAPP_DOCS": self.quikapp_docs,
            "QUIKAPP_SUPPORT": self.quikapp_support
        }
        
        # Replace template variables
        html_content = self.replace_template_variables(template_content, variables)
        
        # Create email
        msg = MIMEMultipart('alternative')
        msg['From'] = f"{self.from_name} <{self.from_email}>"
        msg['To'] = self.to_email
        msg['Subject'] = f"❌ QuikApp Build Failed - {self.app_name} ({self.workflow_name})"
        
        if self.cc_email:
            msg['Cc'] = self.cc_email
        
        if self.bcc_email:
            msg['Bcc'] = self.bcc_email
        
        # Attach HTML content
        html_part = MIMEText(html_content, 'html')
        msg.attach(html_part)
        
        return self.send_email(msg)

    def send_email(self, msg):
        """Send email via SMTP"""
        try:
            print_colored(Colors.BLUE, "📤 Sending email...")
            
            with smtplib.SMTP(self.smtp_server, self.smtp_port) as server:
                server.starttls()
                server.login(self.smtp_user, self.smtp_pass)
                
                text = msg.as_string()
                recipients = [self.to_email]
                if self.cc_email:
                    recipients.extend(self.cc_email.split(','))
                if self.bcc_email:
                    recipients.extend(self.bcc_email.split(','))
                server.sendmail(self.from_email, recipients, text)
            
            print_colored(Colors.GREEN, "✅ Email sent successfully!")
            print_colored(Colors.YELLOW, f"📧 Email sent to: {', '.join(recipients)}")
            print_colored(Colors.YELLOW, f"📧 Subject: {msg['Subject']}")
            
            return True
            
        except Exception as e:
            print_colored(Colors.RED, f"❌ Failed to send email: {str(e)}")
            print_colored(Colors.YELLOW, "💡 Please check your SMTP configuration")
            return False

def main():
    """Main function to handle email notifications"""
    if len(sys.argv) < 2:
        print_colored(Colors.RED, "❌ Usage: python email_notification.py [success|error] [error_message] [error_details]")
        sys.exit(1)
    
    notification_type = sys.argv[1].lower()
    email_system = EmailNotificationSystem()
    
    if notification_type == "success":
        success = email_system.send_success_email()
        sys.exit(0 if success else 1)
    
    elif notification_type == "error":
        if len(sys.argv) < 3:
            error_message = "Build process failed with an unknown error"
        else:
            error_message = sys.argv[2]
        
        if len(sys.argv) < 4:
            error_details = "No additional error details available"
        else:
            error_details = sys.argv[3]
        
        success = email_system.send_error_email(error_message, error_details)
        sys.exit(0 if success else 1)
    
    else:
        print_colored(Colors.RED, "❌ Invalid notification type. Use 'success' or 'error'")
        sys.exit(1)

if __name__ == "__main__":
    main() 