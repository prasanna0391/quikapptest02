#!/usr/bin/env python3

"""
Comprehensive Email Notification System for QuikApp Build System
Supports both success and error notifications with beautiful HTML templates
"""

import os
import sys
import smtplib
import base64
import json
import subprocess
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.base import MIMEBase
from email import encoders
from datetime import datetime
from pathlib import Path
import re

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
        
        # Email configuration
        self.to_email = os.environ.get("EMAIL_ID", "recipient@example.com")
        self.from_email = "no-reply@quikapp.co"
        self.smtp_server = os.environ.get("SMTP_SERVER", "smtp.gmail.com")
        self.smtp_port = int(os.environ.get("SMTP_PORT", "587"))
        self.smtp_user = os.environ.get("SMTP_USERNAME", "no-reply@quikapp.co")
        self.smtp_pass = os.environ.get("SMTP_PASSWORD", "your-app-password")
        
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
        
        # Gmail attachment size limit (25MB)
        self.gmail_size_limit = 25 * 1024 * 1024

    def get_file_size_mb(self, file_path):
        """Get file size in MB"""
        return os.path.getsize(file_path) / (1024 * 1024)

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
                size_mb = self.get_file_size_mb(file_path)
                
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

    def detect_error_type(self, error_message):
        """Detect error type from error message"""
        error_message_lower = error_message.lower()
        
        if any(keyword in error_message_lower for keyword in ["v1 embedding", "flutterapplication", "flutteractivity"]):
            return "Android v1 Embedding Issue"
        elif any(keyword in error_message_lower for keyword in ["resource", "not found", "mipmap", "drawable"]):
            return "Missing Resource Files"
        elif any(keyword in error_message_lower for keyword in ["google-services", "firebase", "package name"]):
            return "Firebase Configuration Error"
        elif any(keyword in error_message_lower for keyword in ["compilation", "syntax", "import"]):
            return "Compilation Error"
        elif any(keyword in error_message_lower for keyword in ["gradle", "build.gradle"]):
            return "Gradle Configuration Error"
        elif any(keyword in error_message_lower for keyword in ["certificate", "provisioning", "code signing"]):
            return "Code Signing Error"
        elif any(keyword in error_message_lower for keyword in ["cocoapods", "pod install"]):
            return "CocoaPods Dependency Error"
        elif any(keyword in error_message_lower for keyword in ["xcode", "archive", "export"]):
            return "Xcode Build Error"
        else:
            return "Unknown Error"

    def generate_resolve_steps(self, error_type):
        """Generate resolution steps based on error type"""
        steps_map = {
            "Android v1 Embedding Issue": [
                "Run the fix_v1_embedding.sh script to resolve Android v1 embedding issues",
                "Ensure all Android files are using v2 embedding",
                "Clean the build cache with 'flutter clean'",
                "Update Flutter to the latest stable version"
            ],
            "Missing Resource Files": [
                "Check that all required resource files exist in android/app/src/main/res/",
                "Verify that launcher icons are properly configured",
                "Run 'flutter pub get' to ensure all dependencies are downloaded",
                "Check for any missing drawable or mipmap resources"
            ],
            "Firebase Configuration Error": [
                "Verify that google-services.json is properly configured",
                "Check that the package name in google-services.json matches your app's package name",
                "Ensure Firebase project is properly set up",
                "Verify Firebase dependencies in pubspec.yaml"
            ],
            "Compilation Error": [
                "Check for syntax errors in Kotlin/Java files",
                "Verify that all required imports are present",
                "Run 'flutter clean' and try building again",
                "Check for any deprecated API usage"
            ],
            "Gradle Configuration Error": [
                "Check Gradle configuration files for errors",
                "Verify that all dependencies are compatible",
                "Try updating Gradle version if needed",
                "Check for any conflicting dependencies"
            ],
            "Code Signing Error": [
                "Verify that certificates and provisioning profiles are valid",
                "Check that the bundle identifier matches the provisioning profile",
                "Ensure certificates are not expired",
                "Verify keychain access and permissions"
            ],
            "CocoaPods Dependency Error": [
                "Run 'cd ios && pod install' to install dependencies",
                "Check for any conflicting pod versions",
                "Update CocoaPods to the latest version",
                "Clean and reinstall pods with 'pod deintegrate && pod install'"
            ],
            "Xcode Build Error": [
                "Check Xcode project settings and configurations",
                "Verify that all required frameworks are linked",
                "Check for any missing entitlements or capabilities",
                "Ensure Xcode version is compatible with your project"
            ],
            "Unknown Error": [
                "Review the error details above for specific issues",
                "Check the build logs for more information",
                "Run 'flutter clean' and try building again",
                "Contact the development team if the issue persists"
            ]
        }
        
        steps = steps_map.get(error_type, steps_map["Unknown Error"])
        steps_html = ""
        
        for i, step in enumerate(steps, 1):
            steps_html += f'<li class="step-item">{step}</li>'
        
        return steps_html

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
            "ARTIFACTS_LIST": artifacts_list
        }
        
        # Replace template variables
        html_content = self.replace_template_variables(template_content, variables)
        
        # Create email
        msg = MIMEMultipart('alternative')
        msg['From'] = self.from_email
        msg['To'] = self.to_email
        msg['Subject'] = f"✅ QuikApp Build Successful - {self.app_name} ({self.workflow_name})"
        
        # Attach HTML content
        html_part = MIMEText(html_content, 'html')
        msg.attach(html_part)
        
        # Attach artifacts if they exist
        if output_dir.exists():
            self.attach_artifacts(msg, output_dir)
        
        return self.send_email(msg, "success")

    def send_error_email(self, error_message, error_details):
        """Send error notification email"""
        print_colored(Colors.BLUE, "📧 Preparing error notification email...")
        
        # Load error template
        template_content = self.load_template("error_email")
        if not template_content:
            return False
        
        # Detect error type and generate resolve steps
        error_type = self.detect_error_type(error_message)
        resolve_steps = self.generate_resolve_steps(error_type)
        
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
            "ERROR_TYPE": error_type,
            "RESOLVE_STEPS": resolve_steps
        }
        
        # Replace template variables
        html_content = self.replace_template_variables(template_content, variables)
        
        # Create email
        msg = MIMEMultipart('alternative')
        msg['From'] = self.from_email
        msg['To'] = self.to_email
        msg['Subject'] = f"❌ QuikApp Build Failed - {self.app_name} ({self.workflow_name})"
        
        # Attach HTML content
        html_part = MIMEText(html_content, 'html')
        msg.attach(html_part)
        
        return self.send_email(msg, "error")

    def attach_artifacts(self, msg, output_dir):
        """Attach build artifacts to email"""
        print_colored(Colors.BLUE, "📎 Attaching artifacts:")
        
        files = list(output_dir.glob("*"))
        large_files = []
        small_files = []
        
        for file_path in files:
            if file_path.is_file():
                file_size = os.path.getsize(file_path)
                
                if file_size > self.gmail_size_limit:
                    large_files.append((file_path, file_size))
                else:
                    small_files.append((file_path, file_size))
        
        # Attach small files
        for file_path, file_size in small_files:
            size_mb = file_size / (1024 * 1024)
            print_colored(Colors.GREEN, f"   - {file_path.name} ({size_mb:.1f} MB)")
            
            try:
                with open(file_path, "rb") as attachment:
                    part = MIMEBase('application', 'octet-stream')
                    part.set_payload(attachment.read())
                
                encoders.encode_base64(part)
                part.add_header(
                    'Content-Disposition',
                    f'attachment; filename= {file_path.name}'
                )
                
                msg.attach(part)
            except Exception as e:
                print_colored(Colors.YELLOW, f"   ⚠️  Failed to attach {file_path.name}: {e}")
        
        # Show large files that couldn't be attached
        if large_files:
            print_colored(Colors.YELLOW, "⚠️  Files too large for email attachment:")
            for file_path, file_size in large_files:
                size_mb = file_size / (1024 * 1024)
                print_colored(Colors.YELLOW, f"   - {file_path.name} ({size_mb:.1f} MB)")

    def send_email(self, msg, email_type):
        """Send email via SMTP"""
        try:
            print_colored(Colors.BLUE, f"📤 Sending {email_type} email...")
            
            server = smtplib.SMTP(self.smtp_server, self.smtp_port)
            server.starttls()
            server.login(self.smtp_user, self.smtp_pass)
            
            text = msg.as_string()
            server.sendmail(self.from_email, self.to_email, text)
            server.quit()
            
            print_colored(Colors.GREEN, f"✅ {email_type.title()} email sent successfully!")
            print_colored(Colors.YELLOW, f"📧 Email sent to: {self.to_email}")
            print_colored(Colors.YELLOW, f"📧 Subject: {msg['Subject']}")
            
            return True
            
        except Exception as e:
            print_colored(Colors.RED, f"❌ Failed to send {email_type} email: {str(e)}")
            print_colored(Colors.YELLOW, "💡 Please check your SMTP configuration")
            
            # Save email content to file for debugging
            email_file = self.project_root / f"build_{email_type}_email_{self.build_id}.html"
            try:
                with open(email_file, 'w', encoding='utf-8') as f:
                    f.write(msg.get_payload()[0].get_payload())
                print_colored(Colors.GREEN, f"✅ Email content saved to: {email_file}")
            except Exception as save_error:
                print_colored(Colors.RED, f"❌ Failed to save email content: {save_error}")
            
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