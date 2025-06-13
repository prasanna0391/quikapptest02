#!/usr/bin/env bash

set -euo pipefail

echo "📦 Generating .p12 certificate from .cer and .key..."

# Check if required environment variables are set
if [ -z "${CERT_CER_PATH:-}" ]; then
    echo "❌ Error: CERT_CER_PATH environment variable is not set"
    exit 1
fi

if [ -z "${PRIVATE_KEY_PATH:-}" ]; then
    echo "❌ Error: PRIVATE_KEY_PATH environment variable is not set"
    exit 1
fi

if [ -z "${GENERATED_P12_PATH:-}" ]; then
    echo "❌ Error: GENERATED_P12_PATH environment variable is not set"
    exit 1
fi

if [ -z "${CERT_PASSWORD:-}" ]; then
    echo "❌ Error: CERT_PASSWORD environment variable is not set"
    exit 1
fi

if [ -z "${KEYCHAIN_PASSWORD:-}" ]; then
    echo "❌ Error: KEYCHAIN_PASSWORD environment variable is not set"
    exit 1
fi

# Check if input files exist
if [ ! -f "$CERT_CER_PATH" ]; then
    echo "❌ Error: Certificate file not found at $CERT_CER_PATH"
    exit 1
fi

if [ ! -f "$PRIVATE_KEY_PATH" ]; then
    echo "❌ Error: Private key file not found at $PRIVATE_KEY_PATH"
    exit 1
fi

# Check if build directory exists
if [ -z "${CM_BUILD_DIR:-}" ]; then
    echo "❌ Error: CM_BUILD_DIR environment variable is not set"
    exit 1
fi

# Create build directory if it doesn't exist
mkdir -p "$CM_BUILD_DIR"

echo "🔐 Certificate generation parameters:"
echo "  Certificate: $CERT_CER_PATH"
echo "  Private Key: $PRIVATE_KEY_PATH"
echo "  Output P12: $GENERATED_P12_PATH"
echo "  Certificate Password: [HIDDEN]"
echo "  P12 Container Password: [HIDDEN]"
echo ""

# Check certificate format and convert if needed
cert_pem_path="$CERT_CER_PATH"
if file "$CERT_CER_PATH" | grep -q "Certificate, Version"; then
    echo "🔧 Certificate is in DER format, converting to PEM..."
    cert_pem_path="$CM_BUILD_DIR/certificate.pem"
    if ! openssl x509 -inform DER -in "$CERT_CER_PATH" -outform PEM -out "$cert_pem_path"; then
        echo "❌ Failed to convert certificate from DER to PEM format"
        exit 1
    fi
    echo "✅ Certificate converted to PEM format: $cert_pem_path"
else
    echo "✅ Certificate is already in PEM format"
fi

# Generate .p12 file from .cer and .key
echo "🔧 Generating .p12 file..."
echo "Using -aes256 to ensure compatible encryption"
echo "Using KEYCHAIN_PASSWORD for the .p12 file container password"
echo "Using CERT_PASSWORD for the private key password (if encrypted)"

if ! openssl pkcs12 -export \
    -inkey "$PRIVATE_KEY_PATH" \
    -in "$cert_pem_path" \
    -out "$GENERATED_P12_PATH" \
    -name "Apple Distribution" \
    -passin "pass:$CERT_PASSWORD" \
    -passout "pass:$KEYCHAIN_PASSWORD" \
    -aes256; then
    echo "❌ Failed to generate .p12"
    echo ""
    echo "Possible reasons:"
    echo "1. Private key ($PRIVATE_KEY_PATH) does not match certificate ($cert_pem_path)"
    echo "2. Passphrase for the private key (if encrypted) is incorrect (check CERT_PASSWORD)"
    echo "3. OpenSSL command syntax error"
    echo "4. Certificate or key file is corrupted"
    echo "5. Insufficient permissions to write to output directory"
    exit 1
fi

echo "✅ .p12 file created at: $GENERATED_P12_PATH"

# Verify .p12 file
echo "🔍 Verifying .p12 file..."
if ! openssl pkcs12 -info -in "$GENERATED_P12_PATH" -passin "pass:$KEYCHAIN_PASSWORD" -nokeys -noout; then
    echo "❌ Verification failed: .p12 password is incorrect or file is corrupt"
    echo "The password used for verification ('$KEYCHAIN_PASSWORD') does not work."
    echo "This indicates an issue with the openssl export process or the password."
    exit 1
fi

echo "✅ .p12 verified successfully and password works"

# Display file information
echo ""
echo "📊 Generated .p12 File Summary:"
echo "File: $GENERATED_P12_PATH"
echo "Size: $(stat -f%z "$GENERATED_P12_PATH" 2>/dev/null || stat -c%s "$GENERATED_P12_PATH" 2>/dev/null || echo "unknown") bytes"
echo "Certificate Name: Apple Distribution"
echo "Encryption: AES-256"
echo ""

# Clean up temporary public key files (if they exist from previous runs)
rm -f "$CM_BUILD_DIR/cert_pubkey.pem" "$CM_BUILD_DIR/key_pubkey.pem" 2>/dev/null || true

# Clean up temporary PEM certificate if we created one
if [ "$cert_pem_path" != "$CERT_CER_PATH" ] && [ -f "$cert_pem_path" ]; then
    rm "$cert_pem_path"
    echo "🧹 Removed temporary PEM certificate file"
fi

echo "✅ All certificate operations completed successfully"
echo "📦 .p12 certificate is ready for code signing" 