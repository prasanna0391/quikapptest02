#!/bin/bash

# QuikApp Email Templates
# This file contains HTML templates for QuikApp email notifications

# Success Email Template
SUCCESS_TEMPLATE() {
    cat << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        @keyframes bounce {
            0%, 20%, 50%, 80%, 100% {transform: translateY(0);}
            40% {transform: translateY(-20px);}
            60% {transform: translateY(-10px);}
        }
        @keyframes shake {
            0%, 100% {transform: translateX(0);}
            10%, 30%, 50%, 70%, 90% {transform: translateX(-5px);}
            20%, 40%, 60%, 80% {transform: translateX(5px);}
        }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            line-height: 1.6;
            color: #333;
            margin: 0;
            padding: 0;
            background-color: #f8f9fa;
        }
        .container {
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
            background: white;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .header {
            background: linear-gradient(135deg, #1A2E5B 0%, #3B5998 100%);
            color: white;
            padding: 30px;
            text-align: center;
            border-radius: 8px 8px 0 0;
        }
        .logo {
            max-width: 150px;
            margin-bottom: 20px;
        }
        .content {
            padding: 30px;
        }
        .status {
            text-align: center;
            margin: 20px 0;
            padding: 15px;
            border-radius: 6px;
            background: #e8f5e9;
            color: #2e7d32;
        }
        .status.error {
            background: #ffebee;
            color: #c62828;
        }
        .status-icon {
            font-size: 48px;
            animation: bounce 2s infinite;
        }
        .status-icon.error {
            animation: shake 0.5s infinite;
        }
        .grid {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 20px;
            margin: 20px 0;
        }
        .grid-item {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 6px;
            border: 1px solid #e9ecef;
        }
        .grid-item h3 {
            margin: 0 0 10px 0;
            color: #495057;
        }
        .grid-item p {
            margin: 0;
            color: #6c757d;
        }
        .artifacts {
            margin: 20px 0;
            padding: 15px;
            background: #f8f9fa;
            border-radius: 6px;
        }
        .artifacts h3 {
            margin: 0 0 10px 0;
            color: #495057;
        }
        .artifacts ul {
            margin: 0;
            padding: 0;
            list-style: none;
        }
        .artifacts li {
            padding: 8px 0;
            border-bottom: 1px solid #e9ecef;
        }
        .artifacts li:last-child {
            border-bottom: none;
        }
        .links {
            margin: 20px 0;
            text-align: center;
        }
        .button {
            display: inline-block;
            padding: 12px 24px;
            background: linear-gradient(135deg, #1A2E5B 0%, #3B5998 100%);
            color: white;
            text-decoration: none;
            border-radius: 6px;
            margin: 10px;
            transition: transform 0.2s;
        }
        .button:hover {
            transform: translateY(-2px);
        }
        .footer {
            text-align: center;
            padding: 20px;
            color: #6c757d;
            font-size: 0.9em;
            border-top: 1px solid #e9ecef;
        }
        .social-links {
            margin: 15px 0;
        }
        .social-links a {
            color: #495057;
            text-decoration: none;
            margin: 0 10px;
        }
        @media (max-width: 600px) {
            .container {
                margin: 10px;
                padding: 10px;
            }
            .grid {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <img src="https://quikapp.co/assets/images/logo.png" alt="QuikApp Logo" class="logo">
            <h1>Build Report</h1>
        </div>
        <div class="content">
            <div class="status">
                <div class="status-icon">✅</div>
                <h2>Build Successful!</h2>
            </div>
            <div class="grid">
                <div class="grid-item">
                    <h3>Project</h3>
                    <p>${APP_NAME:-QuikApp Project}</p>
                </div>
                <div class="grid-item">
                    <h3>Package</h3>
                    <p>${PKG_NAME:-com.quikapp.project}</p>
                </div>
                <div class="grid-item">
                    <h3>Version</h3>
                    <p>${VERSION_NAME:-1.0.0}</p>
                </div>
                <div class="grid-item">
                    <h3>Build Time</h3>
                    <p>$(date '+%Y-%m-%d %H:%M:%S')</p>
                </div>
            </div>
            <div class="artifacts">
                <h3>Build Artifacts</h3>
                <ul>
                    ${ARTIFACT_LIST}
                </ul>
            </div>
            <div class="links">
                <a href="https://app.quikapp.co" class="button">Access Dashboard</a>
                <a href="https://quikapp.co" class="button">Visit Website</a>
            </div>
        </div>
        <div class="footer">
            <div class="social-links">
                <a href="https://twitter.com/quikapp">Twitter</a>
                <a href="https://linkedin.com/company/quikapp">LinkedIn</a>
                <a href="https://github.com/quikapp">GitHub</a>
            </div>
            <p>© $(date +%Y) QuikApp. All rights reserved.</p>
            <p>Convert your website into a mobile app with ease!</p>
        </div>
    </div>
</body>
</html>
EOF
}

# Error Email Template
ERROR_TEMPLATE() {
    cat << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        @keyframes shake {
            0%, 100% {transform: translateX(0);}
            10%, 30%, 50%, 70%, 90% {transform: translateX(-5px);}
            20%, 40%, 60%, 80% {transform: translateX(5px);}
        }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            line-height: 1.6;
            color: #333;
            margin: 0;
            padding: 0;
            background-color: #f8f9fa;
        }
        .container {
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
            background: white;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .header {
            background: linear-gradient(135deg, #A52A2A 0%, #DC3545 100%);
            color: white;
            padding: 30px;
            text-align: center;
            border-radius: 8px 8px 0 0;
        }
        .logo {
            max-width: 150px;
            margin-bottom: 20px;
        }
        .content {
            padding: 30px;
        }
        .status {
            text-align: center;
            margin: 20px 0;
            padding: 15px;
            border-radius: 6px;
            background: #ffebee;
            color: #c62828;
        }
        .status-icon {
            font-size: 48px;
            animation: shake 0.5s infinite;
        }
        .error-details {
            background: #fff3f3;
            padding: 20px;
            border-radius: 6px;
            margin: 20px 0;
            border: 1px solid #ffcdd2;
        }
        .error-details h3 {
            margin: 0 0 10px 0;
            color: #c62828;
        }
        .error-details pre {
            margin: 0;
            padding: 10px;
            background: #fff;
            border-radius: 4px;
            overflow-x: auto;
            font-size: 0.9em;
            white-space: pre-wrap;
            word-wrap: break-word;
        }
        .build-info {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 6px;
            margin: 20px 0;
        }
        .build-info h3 {
            margin: 0 0 10px 0;
            color: #495057;
        }
        .build-info ul {
            margin: 0;
            padding-left: 20px;
            list-style: none;
        }
        .build-info li {
            margin: 5px 0;
            color: #6c757d;
        }
        .build-info li strong {
            color: #495057;
        }
        .resolution-steps {
            margin: 20px 0;
            padding: 15px;
            background: #e8f5e9;
            border-radius: 6px;
            border: 1px solid #c8e6c9;
        }
        .resolution-steps h3 {
            margin: 0 0 10px 0;
            color: #2e7d32;
        }
        .resolution-steps ol {
            margin: 0;
            padding-left: 20px;
        }
        .resolution-steps li {
            margin: 8px 0;
            color: #1b5e20;
        }
        .resolution-steps code {
            background: #fff;
            padding: 2px 4px;
            border-radius: 4px;
            font-family: monospace;
            font-size: 0.9em;
        }
        .links {
            margin: 20px 0;
            text-align: center;
        }
        .button {
            display: inline-block;
            padding: 12px 24px;
            background: linear-gradient(135deg, #A52A2A 0%, #DC3545 100%);
            color: white;
            text-decoration: none;
            border-radius: 6px;
            margin: 10px;
            transition: transform 0.2s;
        }
        .button:hover {
            transform: translateY(-2px);
        }
        .support {
            text-align: center;
            margin: 20px 0;
            padding: 15px;
            background: #fff3f3;
            border-radius: 6px;
        }
        .support h3 {
            margin: 0 0 10px 0;
            color: #c62828;
        }
        .support p {
            margin: 0;
            color: #6c757d;
        }
        .footer {
            text-align: center;
            padding: 20px;
            color: #6c757d;
            font-size: 0.9em;
            border-top: 1px solid #e9ecef;
        }
        .social-links {
            margin: 15px 0;
        }
        .social-links a {
            color: #495057;
            text-decoration: none;
            margin: 0 10px;
        }
        @media (max-width: 600px) {
            .container {
                margin: 10px;
                padding: 10px;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <img src="https://quikapp.co/assets/images/logo.png" alt="QuikApp Logo" class="logo">
            <h1>Build Failed</h1>
        </div>
        <div class="content">
            <div class="status">
                <div class="status-icon">❌</div>
                <h2>Build Failed</h2>
            </div>
            
            <div class="build-info">
                <h3>Build Information</h3>
                <ul>
                    <li><strong>Project:</strong> ${APP_NAME:-QuikApp Project}</li>
                    <li><strong>Package:</strong> ${PKG_NAME:-com.quikapp.project}</li>
                    <li><strong>Version:</strong> ${VERSION_NAME:-1.0.0}</li>
                    <li><strong>Build Time:</strong> $(date '+%Y-%m-%d %H:%M:%S')</li>
                    <li><strong>Build ID:</strong> $(date +%Y%m%d_%H%M%S)</li>
                </ul>
            </div>

            <div class="error-details">
                <h3>Error Details</h3>
                <pre>${ERROR_DETAILS}</pre>
            </div>

            <div class="resolution-steps">
                <h3>🔧 Resolution Steps</h3>
                <ol>
                    <li>Check the error details above for specific issues</li>
                    <li>Review the build logs for more information</li>
                    <li>Run <code>flutter clean</code> and try building again</li>
                    <li>Update dependencies with <code>flutter pub upgrade</code></li>
                    <li>Verify Android SDK and build tools versions</li>
                    <li>Contact the development team if the issue persists</li>
                </ol>
            </div>

            <div class="support">
                <h3>Need Help?</h3>
                <p>Our support team is ready to assist you with any build issues.</p>
            </div>

            <div class="links">
                <a href="https://app.quikapp.co" class="button">Access Dashboard</a>
                <a href="https://quikapp.co/support" class="button">Get Support</a>
            </div>
        </div>
        <div class="footer">
            <div class="social-links">
                <a href="https://twitter.com/quikapp">Twitter</a>
                <a href="https://linkedin.com/company/quikapp">LinkedIn</a>
                <a href="https://github.com/quikapp">GitHub</a>
            </div>
            <p>© $(date +%Y) QuikApp. All rights reserved.</p>
            <p>We're here to help you get your app built!</p>
        </div>
    </div>
</body>
</html>
EOF
}

# Export the templates
export -f SUCCESS_TEMPLATE
export -f ERROR_TEMPLATE 