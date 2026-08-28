#!/bin/bash

# Script untuk menambahkan GitHub Secrets ke sing-box-for-android repository
# Usage: ./add_secrets_android.sh

REPO="shizukumiray-hue/sing-box-for-android"

echo "=== sing-box-for-android GitHub Secrets Setup ==="
echo ""
echo "Repository: $REPO"
echo ""

# Check if gh is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) not found!"
    echo "Install it with: sudo apt install gh"
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo "❌ Not authenticated with GitHub CLI"
    echo "Run: gh auth login"
    exit 1
fi

echo "✓ GitHub CLI authenticated"
echo ""

# Function to add secret
add_secret() {
    local secret_name=$1
    local secret_file=$2
    local is_base64=$3
    
    echo "Adding secret: $secret_name"
    
    if [ ! -f "$secret_file" ]; then
        echo "  ⚠ File not found: $secret_file - SKIPPING"
        return
    fi
    
    if [ "$is_base64" = "yes" ]; then
        # Encode file to base64
        cat "$secret_file" | base64 -w 0 | gh secret set "$secret_name" -R "$REPO"
    else
        # Use file content directly
        cat "$secret_file" | gh secret set "$secret_name" -R "$REPO"
    fi
    
    if [ $? -eq 0 ]; then
        echo "  ✓ $secret_name added successfully"
    else
        echo "  ❌ Failed to add $secret_name"
    fi
}

# Prepare local.properties content
echo "Preparing LOCAL_PROPERTIES..."
cat > /tmp/local.properties << 'PROPS'
KEYSTORE_PASS=your_keystore_password_here
ALIAS_NAME=your_alias_name_here
ALIAS_PASS=your_alias_password_here
PROPS

echo ""
echo "⚠ EDIT /tmp/local.properties dengan nilai yang benar!"
echo "Tekan Enter setelah selesai edit..."
read

# Encode local.properties to base64 and add as secret
echo ""
echo "Adding LOCAL_PROPERTIES (base64 encoded)..."
cat /tmp/local.properties | base64 -w 0 | gh secret set LOCAL_PROPERTIES -R "$REPO"
if [ $? -eq 0 ]; then
    echo "  ✓ LOCAL_PROPERTIES added"
else
    echo "  ❌ Failed to add LOCAL_PROPERTIES"
fi

# Optional: Add keystore secrets (untuk signing di workflow)
echo ""
echo "=== Optional: Keystore Signing Secrets ==="
echo ""
echo "Jika kamu ingin workflow melakukan signing otomatis,"
echo "tambahkan secrets berikut:"
echo ""

# Check if release.keystore exists
KEYSTORE_PATH="app/release.keystore"
if [ -f "$KEYSTORE_PATH" ]; then
    echo "Found keystore: $KEYSTORE_PATH"
    read -p "Add KEYSTORE_FILE secret? (y/n): " add_keystore
    
    if [ "$add_keystore" = "y" ]; then
        echo "Adding KEYSTORE_FILE (base64 encoded)..."
        cat "$KEYSTORE_PATH" | base64 -w 0 | gh secret set KEYSTORE_FILE -R "$REPO"
        if [ $? -eq 0 ]; then
            echo "  ✓ KEYSTORE_FILE added"
        else
            echo "  ❌ Failed to add KEYSTORE_FILE"
        fi
        
        # Add passwords
        echo ""
        read -p "Enter KEYSTORE_PASS: " -s keystore_pass
        echo ""
        echo "$keystore_pass" | gh secret set KEYSTORE_PASS -R "$REPO"
        
        read -p "Enter ALIAS_NAME: " alias_name
        echo "$alias_name" | gh secret set ALIAS_NAME -R "$REPO"
        
        read -p "Enter ALIAS_PASS: " -s alias_pass
        echo ""
        echo "$alias_pass" | gh secret set ALIAS_PASS -R "$REPO"
        
        echo "  ✓ All keystore secrets added"
    fi
else
    echo "⚠ Keystore not found at: $KEYSTORE_PATH"
    echo "  Workflow akan skip signing dan build debug APK"
fi

# Cleanup
rm -f /tmp/local.properties

echo ""
echo "=== Setup Complete! ==="
echo ""
echo "Verify secrets dengan:"
echo "  gh secret list -R $REPO"
echo ""
echo "Trigger build dengan:"
echo "  gh workflow run build-apk-onering.yml -R $REPO"
echo ""
