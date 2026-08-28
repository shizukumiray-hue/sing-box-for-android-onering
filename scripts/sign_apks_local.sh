#!/bin/bash
#
# Local APK Signing Script for sing-box Android (OneRing variant)
#
# This script signs unsigned APKs downloaded from GitHub Actions locally,
# keeping your keystore and signing credentials secure on your machine.
#
# Uses apksigner for v1+v2+v3 signature scheme support (required for Android 7.0+)
#
# USAGE:
#   ./sign_apks_local.sh [OPTIONS]
#
# OPTIONS:
#   -k, --keystore PATH      Path to your keystore file (required)
#   -a, --alias NAME         Key alias name (required)
#   -d, --dir PATH           Directory containing APKs to sign (default: current directory)
#   -h, --help               Show this help message
#
# ENVIRONMENT VARIABLES (alternative to command-line options):
#   KEYSTORE_PATH            Path to keystore file
#   KEYSTORE_PASS            Keystore password
#   KEY_ALIAS                Key alias name
#   KEY_PASS                 Key password (defaults to keystore password if not set)
#
# EXAMPLES:
#   # Sign all APKs in current directory (will prompt for passwords)
#   ./sign_apks_local.sh -k ~/my-release.keystore -a my-key-alias
#
#   # Sign APKs in specific directory
#   ./sign_apks_local.sh -k ~/release.keystore -a mykey -d ~/Downloads
#
#   # Use environment variables (no password prompts)
#   export KEYSTORE_PATH=~/release.keystore
#   export KEYSTORE_PASS=mypassword
#   export KEY_ALIAS=mykey
#   export KEY_PASS=mypassword
#   ./sign_apks_local.sh
#
# PREREQUISITES:
#   - Android SDK build-tools (apksigner command)
#   - Valid Android keystore file
#
# OUTPUT:
#   Signed APKs will be saved with "-signed" suffix
#   Example: SagerNet-arm64-v8a-onering.apk -> SagerNet-arm64-v8a-onering-signed.apk
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
APK_DIR="."
KEYSTORE_PATH="${KEYSTORE_PATH:-}"
KEY_ALIAS="${KEY_ALIAS:-}"
KEYSTORE_PASS="${KEYSTORE_PASS:-}"
KEY_PASS="${KEY_PASS:-}"

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -k|--keystore)
      KEYSTORE_PATH="$2"
      shift 2
      ;;
    -a|--alias)
      KEY_ALIAS="$2"
      shift 2
      ;;
    -d|--dir)
      APK_DIR="$2"
      shift 2
      ;;
    -h|--help)
      grep '^#' "$0" | sed 's/^# \?//'
      exit 0
      ;;
    *)
      echo -e "${RED}Error: Unknown option $1${NC}"
      echo "Use -h or --help for usage information"
      exit 1
      ;;
  esac
done

# Validate required parameters
if [[ -z "$KEYSTORE_PATH" ]]; then
  echo -e "${RED}Error: Keystore path is required${NC}"
  echo "Use -k /path/to/keystore.jks or set KEYSTORE_PATH environment variable"
  exit 1
fi

if [[ -z "$KEY_ALIAS" ]]; then
  echo -e "${RED}Error: Key alias is required${NC}"
  echo "Use -a your-alias-name or set KEY_ALIAS environment variable"
  exit 1
fi

if [[ ! -f "$KEYSTORE_PATH" ]]; then
  echo -e "${RED}Error: Keystore file not found: $KEYSTORE_PATH${NC}"
  exit 1
fi

if [[ ! -d "$APK_DIR" ]]; then
  echo -e "${RED}Error: Directory not found: $APK_DIR${NC}"
  exit 1
fi

# Prompt for passwords if not set
if [[ -z "$KEYSTORE_PASS" ]]; then
  echo -n "Enter keystore password: "
  read -s KEYSTORE_PASS
  echo
fi

if [[ -z "$KEY_PASS" ]]; then
  echo -n "Enter key password (press Enter to use keystore password): "
  read -s KEY_PASS
  echo
  if [[ -z "$KEY_PASS" ]]; then
    KEY_PASS="$KEYSTORE_PASS"
  fi
fi

# Check for required tools
if ! command -v apksigner &> /dev/null; then
  echo -e "${RED}Error: apksigner not found. Please install Android SDK build-tools.${NC}"
  echo "Add Android SDK build-tools to PATH, e.g.:"
  echo "  export PATH=\$PATH:\$ANDROID_HOME/build-tools/34.0.0"
  exit 1
fi

# Find APKs to sign
cd "$APK_DIR"
APKS=($(find . -maxdepth 1 -name "*.apk" ! -name "*-signed.apk" -type f))

if [[ ${#APKS[@]} -eq 0 ]]; then
  echo -e "${YELLOW}No APK files found in $APK_DIR${NC}"
  exit 0
fi

echo -e "${GREEN}Found ${#APKS[@]} APK(s) to sign${NC}"
echo

# Sign each APK
for apk in "${APKS[@]}"; do
  apk_basename=$(basename "$apk")
  signed_apk="${apk%.apk}-signed.apk"
  signed_basename=$(basename "$signed_apk")
  
  echo -e "${GREEN}Processing: $apk_basename${NC}"
  
  # Remove existing signed version if present
  [[ -f "$signed_apk" ]] && rm -f "$signed_apk"
  
  # Sign the APK with apksigner (v1+v2+v3 signature schemes)
  # apksigner automatically aligns the APK before signing
  echo "  Signing with v1+v2+v3 signature schemes..."
  if apksigner sign \
    --ks "$KEYSTORE_PATH" \
    --ks-pass "pass:$KEYSTORE_PASS" \
    --ks-key-alias "$KEY_ALIAS" \
    --key-pass "pass:$KEY_PASS" \
    --out "$signed_apk" \
    "$apk" 2>&1; then
    echo -e "  ${GREEN}✓ Signed successfully${NC}"
  else
    echo -e "  ${RED}✗ Signing failed${NC}"
    rm -f "$signed_apk"
    continue
  fi
  
  # Verify signature
  echo "  Verifying signature..."
  if apksigner verify "$signed_apk" &> /dev/null; then
    echo -e "  ${GREEN}✓ Signature verified${NC}"
    
    # Show signature schemes used
    echo "  Signature schemes:"
    apksigner verify --verbose "$signed_apk" 2>&1 | grep "Verified using" | sed 's/^/    /'
  else
    echo -e "  ${RED}✗ Signature verification failed${NC}"
    rm -f "$signed_apk"
    continue
  fi
  
  # Show file size
  size=$(du -h "$signed_apk" | cut -f1)
  echo -e "  ${GREEN}✓ Complete: $signed_basename ($size)${NC}"
  echo
done

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}All APKs signed successfully!${NC}"
echo -e "${GREEN}================================${NC}"
echo
echo "Signed APKs:"
ls -lh *-signed.apk 2>/dev/null || echo "None"
echo
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Transfer signed APKs to your Android device"
echo "2. Enable 'Install from unknown sources' in Settings"
echo "3. Install the APK for your device architecture"
echo "4. Configure sing-box with OneRing format"
echo
echo "For OneRing configuration help, see: ONERING_CONFIG.md"
