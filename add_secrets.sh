#!/bin/bash

# GitHub Secrets Setup Script for sing-box-for-android
# This script adds required secrets for APK signing

set -e

echo "=================================================="
echo "  GitHub Secrets Setup for sing-box-for-android"
echo "=================================================="
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ Error: GitHub CLI (gh) is not installed"
    echo "Install it with: sudo apt install gh"
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo "❌ Error: Not authenticated with GitHub CLI"
    echo "Run: gh auth login"
    exit 1
fi

# Check if keystore_base64.txt exists
if [ ! -f "keystore_base64.txt" ]; then
    echo "❌ Error: keystore_base64.txt not found"
    echo "Please ensure the keystore base64 file exists in current directory"
    exit 1
fi

echo "✓ GitHub CLI is installed and authenticated"
echo "✓ keystore_base64.txt found"
echo ""

# Prompt for keystore password
echo "Please enter the keystore password:"
read -s KEYSTORE_PASSWORD
echo ""

if [ -z "$KEYSTORE_PASSWORD" ]; then
    echo "❌ Error: Password cannot be empty"
    exit 1
fi

echo "Adding secrets to GitHub repository..."
echo ""

# Add KEYSTORE_FILE
echo "1/4 Adding KEYSTORE_FILE..."
if gh secret set KEYSTORE_FILE < keystore_base64.txt; then
    echo "✓ KEYSTORE_FILE added successfully"
else
    echo "❌ Failed to add KEYSTORE_FILE"
    exit 1
fi

# Add KEYSTORE_PASS
echo "2/4 Adding KEYSTORE_PASS..."
if echo "$KEYSTORE_PASSWORD" | gh secret set KEYSTORE_PASS; then
    echo "✓ KEYSTORE_PASS added successfully"
else
    echo "❌ Failed to add KEYSTORE_PASS"
    exit 1
fi

# Add ALIAS_NAME
echo "3/4 Adding ALIAS_NAME..."
if echo "sing-box-onering" | gh secret set ALIAS_NAME; then
    echo "✓ ALIAS_NAME added successfully"
else
    echo "❌ Failed to add ALIAS_NAME"
    exit 1
fi

# Add ALIAS_PASS (same as keystore password)
echo "4/4 Adding ALIAS_PASS..."
if echo "$KEYSTORE_PASSWORD" | gh secret set ALIAS_PASS; then
    echo "✓ ALIAS_PASS added successfully"
else
    echo "❌ Failed to add ALIAS_PASS"
    exit 1
fi

echo ""
echo "=================================================="
echo "  ✅ All secrets added successfully!"
echo "=================================================="
echo ""

# List secrets to verify
echo "Verifying secrets..."
gh secret list

echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Go to GitHub Actions tab in your repository"
echo "2. Run the 'Build APK with OneRing' workflow manually"
echo "3. Or push to reF1nd-stable branch to trigger automatic build"
echo ""
echo "The APKs will be signed with your keystore automatically."
echo ""
