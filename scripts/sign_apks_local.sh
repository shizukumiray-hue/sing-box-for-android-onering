#!/bin/bash
#
# Local APK Signing Script for sing-box Android (OneRing variant)
#
# This script signs unsigned APKs downloaded from GitHub Actions locally,
# keeping your keystore and signing credentials secure on your machine.
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
#   - Java JDK installed (jarsigner command)
#   - Android SDK build-tools (for zipalign)
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
if ! command -v jarsigner &> /dev/null; then
  echo -e "${RED}Error: jarsigner not found. Please install Java JDK.${NC}"
  exit 1
fi

# Find zipalign
ZIPALIGN=""
if command -v zipalign &> /dev/null; then
  ZIPALIGN="zipalign"
elif [[ -n "$ANDROID_HOME" ]]; then
  # Try to find zipalign in Android SDK
  ZIPALIGN=$(find "$ANDROID_HOME/build-tools" -name zipalign 2>/dev/null | sort -V | tail -n 1)
fi

if [[ -z "$ZIPALIGN" ]]; then
  echo -e "${YELLOW}Warning: zipalign not found. APKs will be signed but not aligned.${NC}"
  echo "Set ANDROID_HOME or add zipalign to PATH for optimal APKs."
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
  
  # Copy unsigned APK to signed name
  cp "$apk" "$signed_apk"
  
  # Sign the APK
  # Use environment variable method to avoid password exposure in process list
  echo "  Signing..."
  export STOREPASS="$KEYSTORE_PASS"
  export KEYPASS="$KEY_PASS"
  jarsigner -verbose \
    -sigalg SHA256withRSA \
    -digestalg SHA-256 \
    -keystore "$KEYSTORE_PATH" \
    -storepass:env STOREPASS \
    -keypass:env KEYPASS \
    "$signed_apk" "$KEY_ALIAS" 2>&1 | grep -E "(signing|adding)" || true
  unset STOREPASS KEYPASS
  
  # Verify signature
  echo "  Verifying signature..."
  if jarsigner -verify -verbose "$signed_apk" 2>&1 | grep -q "jar verified"; then
    echo -e "  ${GREEN}✓ Signature verified${NC}"
  else
    echo -e "  ${RED}✗ Signature verification failed${NC}"
    rm -f "$signed_apk"
    continue
  fi
  
  # Zipalign if available
  if [[ -n "$ZIPALIGN" ]]; then
    echo "  Aligning..."
    temp_apk="${signed_apk}.temp"
    if "$ZIPALIGN" -f 4 "$signed_apk" "$temp_apk" 2>&1; then
      mv "$temp_apk" "$signed_apk"
      echo -e "  ${GREEN}✓ Aligned${NC}"
    else
      echo -e "  ${YELLOW}⚠ Alignment failed, keeping unaligned version${NC}"
      rm -f "$temp_apk"
    fi
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
