# Build and Sign Guide - sing-box Android with OneRing

This guide walks you through building unsigned APKs via GitHub Actions and signing them locally.

---

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Step 1: Generate Android Keystore](#step-1-generate-android-keystore)
4. [Step 2: Trigger GitHub Actions Build](#step-2-trigger-github-actions-build)
5. [Step 3: Download Unsigned APKs](#step-3-download-unsigned-apks)
6. [Step 4: Sign APKs Locally](#step-4-sign-apks-locally)
7. [Step 5: Install on Android Device](#step-5-install-on-android-device)
8. [Troubleshooting](#troubleshooting)
9. [Security Best Practices](#security-best-practices)

---

## Overview

**Why this workflow?**

- ✅ **Keystore stays on your machine** - Never uploaded to GitHub
- ✅ **Individual APK downloads** - Download only the architecture you need
- ✅ **Reproducible builds** - GitHub Actions provides consistent build environment
- ✅ **Easy updates** - Rebuild APKs anytime by triggering workflow

**Architecture:**

```
┌─────────────────────────────────────────────────────────┐
│ GitHub Actions (Cloud)                                   │
│                                                          │
│  1. Build unsigned APKs (5 variants)                    │
│  2. Upload as separate artifacts                        │
│     - arm64-v8a-onering.apk                            │
│     - armeabi-v7a-onering.apk                          │
│     - x86_64-onering.apk                               │
│     - x86-onering.apk                                  │
│     - universal-onering.apk                            │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼ Download
┌─────────────────────────────────────────────────────────┐
│ Your Local Machine                                       │
│                                                          │
│  3. Sign APKs with your keystore                        │
│  4. Verify signatures                                   │
│  5. Transfer to Android device                          │
└─────────────────────────────────────────────────────────┘
```

---

## Prerequisites

### Required Tools

1. **Android SDK Build Tools** (for apksigner)
   ```bash
   # Install via Android Studio or standalone SDK
   # Add to PATH:
   export PATH=$PATH:$ANDROID_SDK_HOME/build-tools/34.0.0
   
   # Verify installation
   apksigner --version
   ```

2. **JDK 17+** (comes with Android Studio or install standalone)
   ```bash
   # Verify
   java -version
   ```

3. **Git** (to clone the repository)
   ```bash
   git --version
   ```

### Required Access

- GitHub account with access to the repository
- Permissions to trigger GitHub Actions workflows

---

## Step 1: Generate Android Keystore

### Option A: Generate New Keystore (First Time)

```bash
# Create keystore directory
mkdir -p ~/.android

# Generate keystore (validity: 10,000 days ≈ 27 years)
keytool -genkey -v \
  -keystore ~/.android/release.keystore \
  -alias release \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000

# You will be prompted for:
# - Keystore password (remember this!)
# - Key password (can be same as keystore password)
# - Your name, organization, city, country, etc.
```

**Example session:**
```
Enter keystore password: [enter password]
Re-enter new password: [confirm password]
What is your first and last name?
  [Unknown]:  John Doe
What is the name of your organizational unit?
  [Unknown]:  Engineering
What is the name of your organization?
  [Unknown]:  MyCompany
What is the name of your City or Locality?
  [Unknown]:  San Francisco
What is the name of your State or Province?
  [Unknown]:  California
What is the two-letter country code for this unit?
  [Unknown]:  US
Is CN=John Doe, OU=Engineering, O=MyCompany, L=San Francisco, ST=California, C=US correct?
  [no]:  yes

Generating 2,048 bit RSA key pair and self-signed certificate (SHA256withRSA) with a validity of 10,000 days
	for: CN=John Doe, OU=Engineering, O=MyCompany, L=San Francisco, ST=California, C=US
Enter key password for <release>
	(RETURN if same as keystore password): [press Enter]
[Storing ~/.android/release.keystore]
```

### Option B: Use Existing Keystore

If you already have a keystore, note its:
- **Path**: e.g., `/home/user/my-release.keystore`
- **Alias**: e.g., `my-key-alias`
- **Password**: keystore and key passwords

### Verify Keystore

```bash
# List keys in keystore
keytool -list -v -keystore ~/.android/release.keystore -alias release

# You should see certificate details
```

### ⚠️ CRITICAL: Backup Your Keystore

```bash
# Backup to secure location (USB drive, password manager, etc.)
cp ~/.android/release.keystore /path/to/secure/backup/

# Store passwords securely:
# - Password manager (recommended)
# - Encrypted file
# - Paper backup in safe location
```

**If you lose your keystore, you cannot update your app - users must uninstall and reinstall.**

---

## Step 2: Trigger GitHub Actions Build

### Method A: Push to Branch (Automatic)

The workflow triggers automatically on push to `reF1nd-stable` branch:

```bash
# Clone repository
git clone https://github.com/yourusername/sing-box-for-android.git
cd sing-box-for-android

# Make changes (optional)
# ...

# Push to trigger build
git checkout reF1nd-stable
git push origin reF1nd-stable
```

### Method B: Manual Trigger (Recommended)

1. Go to GitHub repository
2. Click **Actions** tab
3. Select **Build APK with OneRing** workflow
4. Click **Run workflow** button
5. Confirm branch: `reF1nd-stable`
6. Click **Run workflow**

### Monitor Build Progress

1. In **Actions** tab, click on the running workflow
2. Watch build logs in real-time
3. Build typically takes **8-12 minutes**

**Build steps:**
- ✅ Checkout code
- ✅ Setup Java & Android SDK
- ✅ Verify libbox.aar (prebuilt)
- ✅ Build APKs (5 variants)
- ✅ Upload artifacts

---

## Step 3: Download Unsigned APKs

### Choose Your Architecture

| Architecture | Devices | APK Size | Recommended For |
|--------------|---------|----------|-----------------|
| **arm64-v8a** | Modern Android phones (2016+) | ~9-11 MB | ⭐ Most users |
| **armeabi-v7a** | Older 32-bit ARM devices | ~10-12 MB | Legacy devices |
| **x86_64** | Intel/AMD tablets, emulators | ~11-13 MB | x86 tablets |
| **x86** | Old x86 devices | ~12-14 MB | Rare |
| **universal** | All architectures | ~40-45 MB | Testing/compatibility |

**How to check your device architecture:**
```bash
# Via adb
adb shell getprop ro.product.cpu.abi

# Common outputs:
# arm64-v8a    → Download arm64-v8a APK
# armeabi-v7a  → Download armeabi-v7a APK
# x86_64       → Download x86_64 APK
```

### Download from GitHub Actions

1. In the completed workflow run, scroll to **Artifacts** section
2. Click on the artifact for your architecture:
   - `arm64-v8a-onering`
   - `armeabi-v7a-onering`
   - `x86_64-onering`
   - `x86-onering`
   - `universal-onering`
3. Save ZIP file to your Downloads folder
4. Extract the APK:
   ```bash
   cd ~/Downloads
   unzip arm64-v8a-onering.zip
   # Output: SagerNet-*-arm64-v8a-onering.apk
   ```

**Artifacts expire after 30 days** - download promptly or rebuild.

---

## Step 4: Sign APKs Locally

### Quick Start

```bash
# Navigate to APK directory
cd ~/Downloads

# Run signing script
/path/to/sing-box-for-android/scripts/sign_apks_local.sh \
  -k ~/.android/release.keystore \
  -a release

# Enter passwords when prompted
```

### Detailed Steps

1. **Copy signing script** (first time only):
   ```bash
   cp sing-box-for-android/scripts/sign_apks_local.sh ~/bin/
   chmod +x ~/bin/sign_apks_local.sh
   ```

2. **Sign APKs**:
   ```bash
   cd ~/Downloads
   
   # Sign all APKs in current directory
   sign_apks_local.sh \
     -k ~/.android/release.keystore \
     -a release \
     -d .
   
   # Enter keystore password: ********
   # Enter key password (or press Enter): ********
   ```

3. **Verify output**:
   ```
   [INFO] Found 1 APK(s) to sign
   [INFO] Processing: SagerNet-...-arm64-v8a-onering.apk
     Signing with v1+v2+v3 signature schemes...
     ✓ Signed successfully
     Verifying signature...
     ✓ Signature verified
     Signature schemes:
       Verified using v1 scheme (JAR signing): true
       Verified using v2 scheme (APK Signature Scheme v2): true
       Verified using v3 scheme (APK Signature Scheme v3): true
     ✓ Complete: SagerNet-...-arm64-v8a-onering-signed.apk (9.2M)
   
   ================================
   All APKs signed successfully!
   ================================
   ```

### Using Environment Variables (No Password Prompts)

```bash
export KEYSTORE_PATH=~/.android/release.keystore
export KEYSTORE_PASS=your_keystore_password
export KEY_ALIAS=release
export KEY_PASS=your_key_password

cd ~/Downloads
sign_apks_local.sh
```

**⚠️ Security Warning**: Passwords in environment variables are visible in process lists. Use only on secure, personal machines.

### Batch Signing (Multiple APKs)

```bash
# Download all 5 variants
cd ~/Downloads
unzip arm64-v8a-onering.zip
unzip armeabi-v7a-onering.zip
unzip x86_64-onering.zip
unzip x86-onering.zip
unzip universal-onering.zip

# Sign all at once
sign_apks_local.sh -k ~/.android/release.keystore -a release

# Result: 5 signed APKs
# SagerNet-*-arm64-v8a-onering-signed.apk
# SagerNet-*-armeabi-v7a-onering-signed.apk
# ...
```

---

## Step 5: Install on Android Device

### Method A: USB Transfer (Recommended)

```bash
# Enable USB debugging on Android device:
# Settings → About Phone → Tap "Build Number" 7 times
# Settings → Developer Options → Enable USB Debugging

# Connect device and verify
adb devices

# Install signed APK
adb install ~/Downloads/SagerNet-*-arm64-v8a-onering-signed.apk

# If app already installed (update):
adb install -r ~/Downloads/SagerNet-*-arm64-v8a-onering-signed.apk
```

### Method B: File Transfer

1. Connect device to computer (USB or Wi-Fi)
2. Copy signed APK to device:
   - USB: Copy to `Download` or `Documents` folder
   - Cloud: Upload to Google Drive, Dropbox, etc.
3. On Android device:
   - Open **Files** app or download manager
   - Navigate to signed APK
   - Tap to install

### Method C: Web Transfer

```bash
# Start simple HTTP server
cd ~/Downloads
python3 -m http.server 8080

# On Android device:
# 1. Connect to same Wi-Fi network
# 2. Open browser
# 3. Navigate to: http://YOUR_COMPUTER_IP:8080
# 4. Download signed APK
# 5. Install from Downloads
```

### Enable Installation from Unknown Sources

If prompted, enable installation:

**Android 8.0+ (Oreo and newer):**
1. Tap **Settings** when prompted
2. Enable **Allow from this source**
3. Go back and retry installation

**Android 7.1 and older:**
1. Go to **Settings → Security**
2. Enable **Unknown sources**
3. Confirm warning
4. Retry installation

---

## Troubleshooting

### Build Issues

**Problem**: Workflow fails at "Verify libbox.aar"

**Solution**: Ensure `sing-box-for-android/app/libs/libbox.aar` exists and is valid (84MB+)
```bash
ls -lh sing-box-for-android/app/libs/libbox.aar
unzip -l sing-box-for-android/app/libs/libbox.aar | grep libgojni.so
```

**Problem**: Gradle build fails

**Solution**: Check workflow logs for specific error. Common causes:
- Missing dependencies in `build.gradle.kts`
- NDK version mismatch
- Java version incompatibility

### Signing Issues

**Problem**: `apksigner: command not found`

**Solution**: Install Android SDK Build Tools and add to PATH
```bash
export PATH=$PATH:$ANDROID_SDK_HOME/build-tools/34.0.0
```

**Problem**: "Keystore was tampered with, or password was incorrect"

**Solution**: Verify password is correct
```bash
keytool -list -v -keystore ~/.android/release.keystore
```

**Problem**: Signing succeeds but verification fails

**Solution**: Re-sign with clean APK
```bash
rm *-signed.apk
sign_apks_local.sh -k ~/.android/release.keystore -a release
```

### Installation Issues

**Problem**: "App not installed" error

**Possible causes**:
1. **Architecture mismatch**: Download correct variant for your device
2. **Corrupted APK**: Re-download and re-sign
3. **Signature conflict**: Uninstall old version first
4. **Insufficient storage**: Free up space

**Solution**:
```bash
# Uninstall old version
adb uninstall io.nekohasekai.sagernet

# Install fresh signed APK
adb install ~/Downloads/SagerNet-*-arm64-v8a-onering-signed.apk
```

**Problem**: Installation succeeds but app crashes on launch

**Solutions**:
1. Check device architecture matches APK
2. Check Android version compatibility (Android 5.0+ required)
3. Check logcat for errors:
   ```bash
   adb logcat | grep SagerNet
   ```

---

## Security Best Practices

### Keystore Security

✅ **DO**:
- Store keystore in encrypted location
- Use strong passwords (16+ characters, mixed case, numbers, symbols)
- Backup keystore to multiple secure locations
- Use password manager for credentials
- Restrict file permissions: `chmod 600 ~/.android/release.keystore`

❌ **DON'T**:
- Commit keystore to Git
- Upload keystore to cloud without encryption
- Share keystore passwords via email/chat
- Reuse passwords across keystores
- Store passwords in plain text

### Build Security

✅ **DO**:
- Review workflow changes before merging
- Verify artifact checksums
- Build from trusted branches only
- Monitor workflow execution logs

❌ **DON'T**:
- Accept workflow files from untrusted sources
- Disable APK signature verification
- Install unsigned APKs
- Skip artifact verification

### Device Security

✅ **DO**:
- Download APKs over HTTPS only
- Verify APK signatures before installation
- Keep "Unknown sources" disabled when not installing
- Use VPN or trusted network for downloads

❌ **DON'T**:
- Install APKs from unknown sources
- Share signed APKs publicly (your signature!)
- Install on rooted devices without additional security

---

## Automation Scripts

### Automated Download and Sign (Advanced)

```bash
#!/bin/bash
# auto_build_sign.sh - Automated workflow

KEYSTORE_PATH=~/.android/release.keystore
KEY_ALIAS=release
DOWNLOAD_DIR=~/Downloads/singbox-builds
ARCH=arm64-v8a

# Ensure download directory exists
mkdir -p "$DOWNLOAD_DIR"
cd "$DOWNLOAD_DIR"

# TODO: Download artifact via GitHub API or CLI
# gh run download <run-id> -n ${ARCH}-onering

# Extract
unzip -o ${ARCH}-onering.zip

# Sign
sign_apks_local.sh -k "$KEYSTORE_PATH" -a "$KEY_ALIAS"

# Install via adb
adb install -r *-${ARCH}-onering-signed.apk

echo "Build, sign, and install complete!"
```

---

## Next Steps

After installing the signed APK:

1. **Configure OneRing**: See [ONERING_CONFIG.md](ONERING_CONFIG.md)
2. **Test connection**: Verify bypass works with your ISP
3. **Monitor performance**: Check speeds and stability
4. **Regular updates**: Rebuild APKs when new features are released

---

## FAQ

**Q: Do I need to sign APKs every time I update?**
A: Yes, but you must use the **same keystore and alias**. Android will reject updates signed with different keys.

**Q: Can I share signed APKs with others?**
A: Technically yes, but not recommended. Each user should sign with their own keystore for security and update control.

**Q: How do I update the app?**
A: Build new APKs, sign with **same keystore**, install over existing app. Android preserves app data.

**Q: Can I use GitHub Secrets for signing?**
A: Not recommended. Uploading your keystore to GitHub (even encrypted) increases attack surface. Local signing is more secure.

**Q: What if I lose my keystore?**
A: You cannot update the app. Users must uninstall and reinstall with new keystore. **BACKUP YOUR KEYSTORE!**

**Q: Can I automate the entire process?**
A: Partially. You can automate build triggering and downloading, but local signing requires manual password entry (for security).

---

## Support

- **Issues**: https://github.com/yourusername/sing-box-for-android/issues
- **Discussions**: https://github.com/yourusername/sing-box-for-android/discussions
- **Documentation**: See repository README.md

---

**Last Updated**: 2026-08-28  
**Version**: 1.0
