#!/bin/bash

# SETTINGS
EMAIL="prasannasrinivasan43@gmail.com"
KEY_FILE="$HOME/.ssh/id_ed25519"

echo "🔐 Generating a new SSH key for GitHub..."
ssh-keygen -t ed25519 -C "$EMAIL" -f "$KEY_FILE"

echo "🚀 Starting ssh-agent..."
eval "$(ssh-agent -s)"

echo "➕ Adding SSH key to agent..."
ssh-add "$KEY_FILE"

echo "📋 Copying public key to clipboard (macOS only)..."
pbcopy < "${KEY_FILE}.pub"

echo "✅ SSH key generated and copied to clipboard!"
echo "👉 Now go to: https://github.com/settings/keys"
echo "🔗 Click 'New SSH Key', paste it, name it (e.g., 'MacBook M1'), and save."

read -p "🛑 Press ENTER after you've added the key to GitHub..."

echo "🔍 Testing SSH connection to GitHub..."
ssh -T git@github.com

if [ $? -eq 1 ]; then
  echo "✅ SSH authentication looks good!"
else
  echo "❌ SSH authentication failed. Please check your key and try again."
  exit 1
fi

echo "📦 Setting remote origin to SSH (for your current repo)..."
git remote set-url origin git@github.com:prasanna0391/quikapptest02.git

echo "📤 Trying to push to GitHub..."
git push -u origin main

echo "🎉 All done!"
