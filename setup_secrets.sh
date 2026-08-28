#!/bin/bash

# 🔐 GitHub Secrets Setup Helper Script
# sing-box Android OneRing - Keystore Encoder

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=========================================="
echo "🔐 GitHub Secrets Setup Helper"
echo "=========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "ℹ️  $1"
}

# Check if keystore file exists
KEYSTORE_FILE="$PROJECT_ROOT/release.keystore"

if [ ! -f "$KEYSTORE_FILE" ]; then
    KEYSTORE_FILE="$SCRIPT_DIR/release.keystore"
fi

if [ ! -f "$KEYSTORE_FILE" ]; then
    print_error "Keystore file not found!"
    echo ""
    echo "Searched in:"
    echo "  - $PROJECT_ROOT/release.keystore"
    echo "  - $SCRIPT_DIR/release.keystore"
    echo ""
    echo "Please specify keystore file path:"
    read -p "Keystore path: " KEYSTORE_FILE
    
    if [ ! -f "$KEYSTORE_FILE" ]; then
        print_error "File not found: $KEYSTORE_FILE"
        exit 1
    fi
fi

print_success "Found keystore: $KEYSTORE_FILE"
echo ""

# Get keystore info
KEYSTORE_SIZE=$(ls -lh "$KEYSTORE_FILE" | awk '{print $5}')
print_info "Keystore size: $KEYSTORE_SIZE"
echo ""

# Step 1: Get keystore password
echo "=========================================="
echo "Step 1: Keystore Password"
echo "=========================================="
echo ""
echo "Enter keystore password (or press Enter to try common passwords):"
read -s -p "Password: " KEYSTORE_PASS
echo ""

if [ -z "$KEYSTORE_PASS" ]; then
    print_info "Trying common passwords..."
    
    COMMON_PASSWORDS=("android" "123456" "password" "changeit")
    FOUND_PASSWORD=""
    
    for pwd in "${COMMON_PASSWORDS[@]}"; do
        echo -n "  Trying: $pwd ... "
        if keytool -list -keystore "$KEYSTORE_FILE" -storepass "$pwd" > /dev/null 2>&1; then
            print_success "Success!"
            FOUND_PASSWORD="$pwd"
            KEYSTORE_PASS="$pwd"
            break
        else
            echo "Failed"
        fi
    done
    
    if [ -z "$FOUND_PASSWORD" ]; then
        print_error "Could not find correct password"
        echo ""
        echo "Please enter the correct password:"
        read -s -p "Password: " KEYSTORE_PASS
        echo ""
    fi
fi

# Verify keystore password
echo ""
print_info "Verifying keystore password..."
if ! keytool -list -keystore "$KEYSTORE_FILE" -storepass "$KEYSTORE_PASS" > /dev/null 2>&1; then
    print_error "Invalid keystore password!"
    exit 1
fi
print_success "Keystore password is correct"
echo ""

# Step 2: List aliases
echo "=========================================="
echo "Step 2: Keystore Aliases"
echo "=========================================="
echo ""
print_info "Listing keystore aliases..."
echo ""

ALIAS_LIST=$(keytool -list -keystore "$KEYSTORE_FILE" -storepass "$KEYSTORE_PASS" 2>&1 | grep "Alias name:" | awk '{print $3}')

if [ -z "$ALIAS_LIST" ]; then
    print_error "No aliases found in keystore"
    exit 1
fi

echo "Available aliases:"
echo "$ALIAS_LIST" | nl
echo ""

# Get alias name
ALIAS_COUNT=$(echo "$ALIAS_LIST" | wc -l)
if [ "$ALIAS_COUNT" -eq 1 ]; then
    ALIAS_NAME=$(echo "$ALIAS_LIST" | head -1)
    print_info "Using alias: $ALIAS_NAME"
else
    echo "Select alias number (default: 1):"
    read -p "Alias #: " ALIAS_NUM
    ALIAS_NUM=${ALIAS_NUM:-1}
    ALIAS_NAME=$(echo "$ALIAS_LIST" | sed -n "${ALIAS_NUM}p")
    print_info "Selected alias: $ALIAS_NAME"
fi
echo ""

# Step 3: Get alias password
echo "=========================================="
echo "Step 3: Alias Password"
echo "=========================================="
echo ""
echo "Enter alias password (or press Enter to use same as keystore password):"
read -s -p "Alias password: " ALIAS_PASS
echo ""

if [ -z "$ALIAS_PASS" ]; then
    ALIAS_PASS="$KEYSTORE_PASS"
    print_info "Using keystore password for alias"
fi
echo ""

# Verify alias password
print_info "Verifying alias password..."
if ! keytool -list -keystore "$KEYSTORE_FILE" -storepass "$KEYSTORE_PASS" -alias "$ALIAS_NAME" -keypass "$ALIAS_PASS" > /dev/null 2>&1; then
    print_error "Invalid alias password!"
    exit 1
fi
print_success "Alias password is correct"
echo ""

# Step 4: Encode keystore to base64
echo "=========================================="
echo "Step 4: Encode Keystore"
echo "=========================================="
echo ""
print_info "Encoding keystore to base64..."

KEYSTORE_BASE64=$(base64 -w 0 "$KEYSTORE_FILE")
KEYSTORE_BASE64_LEN=${#KEYSTORE_BASE64}

print_success "Keystore encoded successfully ($KEYSTORE_BASE64_LEN bytes)"
echo ""

# Step 5: Display secrets
echo "=========================================="
echo "Step 5: GitHub Secrets"
echo "=========================================="
echo ""
print_success "All secrets ready! Copy these to GitHub:"
echo ""
echo "----------------------------------------"
echo "Secret Name: KEYSTORE_FILE"
echo "Secret Value:"
echo "$KEYSTORE_BASE64"
echo ""
echo "----------------------------------------"
echo "Secret Name: KEYSTORE_PASS"
echo "Secret Value: $KEYSTORE_PASS"
echo ""
echo "----------------------------------------"
echo "Secret Name: ALIAS_NAME"
echo "Secret Value: $ALIAS_NAME"
echo ""
echo "----------------------------------------"
echo "Secret Name: ALIAS_PASS"
echo "Secret Value: $ALIAS_PASS"
echo "----------------------------------------"
echo ""

# Save to file
OUTPUT_FILE="$SCRIPT_DIR/github_secrets.txt"
cat > "$OUTPUT_FILE" << EOF
========================================
🔐 GitHub Secrets for sing-box Android
========================================
Generated: $(date)
Keystore: $KEYSTORE_FILE

Copy these secrets to GitHub:
https://github.com/shizukumiray-hue/sing-box-for-android-onering/settings/secrets/actions

========================================
Secret 1: KEYSTORE_FILE
========================================
$KEYSTORE_BASE64

========================================
Secret 2: KEYSTORE_PASS
========================================
$KEYSTORE_PASS

========================================
Secret 3: ALIAS_NAME
========================================
$ALIAS_NAME

========================================
Secret 4: ALIAS_PASS
========================================
$ALIAS_PASS

========================================
Setup Instructions:
========================================

1. Go to: https://github.com/shizukumiray-hue/sing-box-for-android-onering/settings/secrets/actions

2. Click "New repository secret"

3. Add each secret one by one:
   - Name: KEYSTORE_FILE
     Value: (copy the long base64 string above)
   
   - Name: KEYSTORE_PASS
     Value: $KEYSTORE_PASS
   
   - Name: ALIAS_NAME
     Value: $ALIAS_NAME
   
   - Name: ALIAS_PASS
     Value: $ALIAS_PASS

4. Verify all 4 secrets are added

5. Run workflow: Build APK with OneRing (Fixed)

========================================
⚠️  SECURITY WARNING
========================================
This file contains sensitive information!
- DO NOT commit this file to git
- DO NOT share this file publicly
- DELETE this file after copying secrets to GitHub

File location: $OUTPUT_FILE
EOF

print_success "Secrets saved to: $OUTPUT_FILE"
echo ""

print_warning "SECURITY WARNING:"
echo "  - This file contains sensitive data"
echo "  - DELETE it after copying secrets to GitHub"
echo "  - DO NOT commit it to git"
echo ""

# Step 6: Summary
echo "=========================================="
echo "📋 Next Steps"
echo "=========================================="
echo ""
echo "1. Open GitHub repository settings:"
echo "   https://github.com/shizukumiray-hue/sing-box-for-android-onering/settings/secrets/actions"
echo ""
echo "2. Click 'New repository secret' and add all 4 secrets from above"
echo ""
echo "3. Or use the saved file:"
echo "   cat $OUTPUT_FILE"
echo ""
echo "4. After adding secrets, run the workflow:"
echo "   - Go to Actions tab"
echo "   - Select 'Build APK with OneRing (Fixed)'"
echo "   - Click 'Run workflow'"
echo ""
print_success "Setup complete! 🎉"
echo ""
