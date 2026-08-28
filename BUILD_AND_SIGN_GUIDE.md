# Build and Sign Guide for sing-box Android with OneRing

This guide walks you through building unsigned APKs via GitHub Actions and signing them locally on your machine, keeping your keystore credentials secure.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Generate Android Keystore](#generate-android-keystore)
3. [Trigger GitHub Actions Build](#trigger-github-actions-build)
4. [Download Unsigned APKs](#download-unsigned-apks)
5. [Sign APKs Locally](#sign-apks-locally)
6. [Install on Device](#install-on-device)
7. [Configure OneRing](#configure-onering)
8. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### On Your Local Machine

- **Java JDK** (version 8 or higher)
  ```bash
  # Check if installed
  java -version
  javac -version
  
  # Install on Ubuntu/Debian
  sudo apt install openjdk-17-jdk
  
  # Install on macOS
  brew install openjdk@17
  
  # Install on Windows
  # Download from https://adoptium.net/
  ```

- **Android SDK Build Tools** (for zipalign - optional but recommended)
  ```bash
  # If you have Android Studio, SDK is already installed
  # Set ANDROID_HOME environment variable
  export ANDROID_HOME=$HOME/Android/Sdk  # Linux/macOS
  set ANDROID_HOME=C:\Users\YourName\AppData\Local\Android\Sdk  # Windows
  ```

- **Git** (to clone repository if needed)

### On GitHub

- GitHub account with access to this repository
- Fork or write access to trigger workflows

---

## Generate Android Keystore

If you don't already have a keystore, create one:

```bash
# Navigate to a secure location
cd ~/secure-keys/  # or any secure directory

# Generate keystore
keytool -genkey -v \
  -keystore sing-box-release.keystore \
  -alias sing-box-key \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -storepass YourKeystorePassword \
  -keypass YourKeyPassword
```

You'll be prompted for:
- Your name and organizational unit
- Organization name
- City, State, Country

**IMPORTANT:**
- Store keystore file securely (backup to encrypted storage)
- Remember your passwords (write them down securely)
- **NEVER** commit keystore to git or share publicly
- If you lose the keystore, you cannot update your app on Play Store

### Keystore Information to Remember

```
Keystore file: sing-box-release.keystore
Keystore password: ********
Key alias: sing-box-key
Key password: ******** (can be same as keystore password)
```

---

## Trigger GitHub Actions Build

### Option 1: Manual Trigger (Recommended)

1. Go to your GitHub repository
2. Navigate to **Actions** tab
3. Click **Build APK with OneRing** workflow
4. Click **Run workflow** button (top right)
5. Leave `libbox_run_id` empty (will use prebuilt libbox.aar)
6. Click green **Run workflow** button

### Option 2: Push to Branch

Push changes to `reF1nd-stable` branch:

```bash
git checkout reF1nd-stable
git push origin reF1nd-stable
```

This automatically triggers the build if changes affect:
- `app/**`
- `build.gradle.kts`
- `version.properties`
- `.github/workflows/build-apk-onering.yml`

### Build Process

The workflow will:
1. ✅ Verify prebuilt `libbox.aar` (84MB with OneRing implementation)
2. ✅ Build APKs for all architectures (arm64-v8a, armeabi-v7a, x86_64, x86, universal)
3. ✅ Rename APKs with `-onering` suffix
4. ✅ Upload each APK as separate artifact
5. ⏱️ Takes approximately 5-8 minutes

### Monitor Build Progress

Watch the workflow run:
- Green checkmark ✅ = Success
- Red X ❌ = Failed (check logs)
- Yellow circle 🟡 = Running

---

## Download Unsigned APKs

### Method 1: GitHub Web Interface

1. Go to the completed workflow run
2. Scroll down to **Artifacts** section
3. Download the architecture you need:
   - `arm64-v8a-onering` - Modern 64-bit ARM phones (most common, recommended)
   - `armeabi-v7a-onering` - Older 32-bit ARM phones
   - `x86_64-onering` - 64-bit x86 emulators/tablets
   - `x86-onering` - 32-bit x86 devices (rare)
   - `universal-onering` - All architectures (~40MB, larger but works everywhere)

4. Extract the ZIP file to get the APK

### Method 2: GitHub CLI (gh)

```bash
# Install gh if not already installed
# https://cli.github.com/

# List recent workflow runs
gh run list --workflow=build-apk-onering.yml

# Download artifacts from latest run
gh run download --name arm64-v8a-onering

# Or download all artifacts
gh run download <run-id>
```

### Which Architecture Do I Need?

Check your device:

**Android Device:**
```bash
adb shell getprop ro.product.cpu.abi
# Output examples:
# arm64-v8a → Download arm64-v8a-onering
# armeabi-v7a → Download armeabi-v7a-onering
```

**If unsure:** Download `universal-onering` (works on all devices but larger file size)

---

## Sign APKs Locally

### Quick Start

```bash
# Navigate to directory with downloaded APKs
cd ~/Downloads/

# Run signing script (will prompt for passwords)
/path/to/sing-box-for-android/scripts/sign_apks_local.sh \
  --keystore ~/secure-keys/sing-box-release.keystore \
  --alias sing-box-key
```

### Using Environment Variables (No Password Prompts)

```bash
# Set environment variables
export KEYSTORE_PATH=~/secure-keys/sing-box-release.keystore
export KEYSTORE_PASS=YourKeystorePassword
export KEY_ALIAS=sing-box-key
export KEY_PASS=YourKeyPassword

# Run script
/path/to/sing-box-for-android/scripts/sign_apks_local.sh
```

### Sign APKs in Specific Directory

```bash
./scripts/sign_apks_local.sh \
  -k ~/secure-keys/sing-box-release.keystore \
  -a sing-box-key \
  -d ~/Downloads/unsigned-apks/
```

### Expected Output

```
Found 1 APK(s) to sign

Processing: SagerNet-arm64-v8a-onering.apk
  Signing...
  Verifying signature...
  ✓ Signature verified
  Aligning...
  ✓ Aligned
  ✓ Complete: SagerNet-arm64-v8a-onering-signed.apk (18M)

================================
All APKs signed successfully!
================================

Signed APKs:
-rw-r--r-- 1 user user 18M Aug 28 17:30 SagerNet-arm64-v8a-onering-signed.apk
```

### Verify Signature Manually

```bash
# Check signature details
jarsigner -verify -verbose -certs SagerNet-arm64-v8a-onering-signed.apk

# Should output: "jar verified."
```

---

## Install on Device

### Via USB (ADB)

```bash
# Connect device via USB, enable USB debugging

# Install signed APK
adb install SagerNet-arm64-v8a-onering-signed.apk

# If updating existing app
adb install -r SagerNet-arm64-v8a-onering-signed.apk

# If different signature (will uninstall old version)
adb install -r -d SagerNet-arm64-v8a-onering-signed.apk
```

### Via File Transfer

1. Transfer APK to device (USB, email, cloud storage, etc.)
2. On device: Go to **Settings** → **Security**
3. Enable **Install from unknown sources** or **Install unknown apps**
4. Use file manager to locate APK
5. Tap APK and follow installation prompts

### Via HTTP Server (Quick Method)

```bash
# On your computer, in directory with APK
python3 -m http.server 8080

# On phone browser, navigate to:
# http://YOUR_COMPUTER_IP:8080/SagerNet-arm64-v8a-onering-signed.apk
```

---

## Configure OneRing

### Quick Configuration

1. Open sing-box/SagerNet app
2. Add new outbound/server
3. Choose protocol (VLESS, VMess, or Trojan)
4. In **TLS Settings** → **Server Name**, use OneRing format:
   ```
   onering:real-domain.com:bug-domain.com
   ```

### Example Configuration

**VLESS + WebSocket:**
```json
{
  "type": "vless",
  "server": "bug.telkomsel.com",
  "server_port": 443,
  "uuid": "your-uuid",
  "tls": {
    "enabled": true,
    "server_name": "onering:my-cdn.cloudflare.com:bug.telkomsel.com"
  },
  "transport": {
    "type": "ws",
    "path": "/vless",
    "headers": {
      "Host": "my-cdn.cloudflare.com"
    }
  }
}
```

**For detailed OneRing configuration, see:** [ONERING_CONFIG.md](ONERING_CONFIG.md)

---

## Troubleshooting

### Build Issues

#### Issue: Workflow fails at "Verify libbox.aar"

**Solution:**
```bash
# Check if libbox.aar exists and is valid
ls -lh sing-box-for-android/app/libs/libbox.aar

# Should be ~84MB
# If missing or corrupted, rebuild it from sing-box core
```

#### Issue: "Gradle build failed"

**Solution:**
- Check workflow logs for specific error
- Common causes: dependency resolution, NDK version mismatch
- Verify `version.properties` and `build.gradle.kts` syntax

### Signing Issues

#### Issue: "jarsigner: command not found"

**Solution:**
```bash
# Install Java JDK
sudo apt install openjdk-17-jdk  # Ubuntu/Debian
brew install openjdk@17          # macOS

# Verify installation
which jarsigner
```

#### Issue: "keystore password was incorrect"

**Solution:**
- Double-check password (case-sensitive)
- Verify keystore file path is correct
- Try entering password manually when prompted

#### Issue: "zipalign not found" warning

**Solution:**
```bash
# Set ANDROID_HOME environment variable
export ANDROID_HOME=$HOME/Android/Sdk

# Or install Android SDK build-tools
# APKs will still work without zipalign, just slightly less optimized
```

### Installation Issues

#### Issue: "App not installed" on device

**Solutions:**
1. **Signature conflict:** Uninstall existing app first
2. **Corrupted APK:** Re-download and re-sign
3. **Wrong architecture:** Download correct architecture APK
4. **Insufficient storage:** Free up space on device

#### Issue: "For security reasons, your phone is not allowed to install unknown apps from this source"

**Solution:**
- Go to **Settings** → **Apps** → **Special access** → **Install unknown apps**
- Find your file manager or browser
- Enable "Allow from this source"

#### Issue: App installs but crashes on launch

**Solutions:**
1. Check Android version (requires Android 5.0+)
2. Verify architecture matches device
3. Check logcat for crash details:
   ```bash
   adb logcat | grep -i "singbox\|sagernet"
   ```

### OneRing Connection Issues

#### Issue: "Connection timeout" or "Cannot connect"

**Solutions:**
1. Test without OneRing first (use real domain directly)
2. Verify bug domain resolves: `dig +short bug.domain.com`
3. Check server is accessible from bug domain IP
4. Enable debug logging to see detailed connection flow

#### Issue: Connection works without OneRing, fails with OneRing

**Solutions:**
1. Verify format: `onering:real:bug` (no spaces)
2. Check CDN supports Host header routing
3. Ensure server certificate matches real domain
4. Try different bug domain

**For more OneRing troubleshooting:** See [ONERING_CONFIG.md](ONERING_CONFIG.md#troubleshooting)

---

## Security Best Practices

### Keystore Security

- ✅ **DO:** Store keystore in encrypted location
- ✅ **DO:** Backup keystore to secure offline storage
- ✅ **DO:** Use strong passwords (12+ characters)
- ❌ **DON'T:** Commit keystore to git
- ❌ **DON'T:** Share keystore publicly
- ❌ **DON'T:** Email or upload keystore to cloud unencrypted

### APK Distribution

- Only distribute signed APKs from trusted builds
- Verify APK signature before distribution
- Use HTTPS for APK hosting
- Consider code signing certificate for Play Store release

### GitHub Secrets

- This build process does NOT use GitHub Secrets for signing
- Keystore stays on your local machine only
- No credentials stored in GitHub Actions

---

## Advanced: Automated Signing Pipeline

If you want to automate signing while keeping keystore local:

```bash
#!/bin/bash
# watch-and-sign.sh - Monitor GitHub for new builds and auto-sign

WORKFLOW="build-apk-onering.yml"
CHECK_INTERVAL=300  # 5 minutes

while true; do
  # Get latest run
  RUN_ID=$(gh run list --workflow=$WORKFLOW --limit 1 --json databaseId --jq '.[0].databaseId')
  
  # Check if already processed
  if [[ ! -f ".processed/$RUN_ID" ]]; then
    # Download and sign
    gh run download $RUN_ID --name arm64-v8a-onering
    ./scripts/sign_apks_local.sh -k ~/keystore.jks -a mykey
    
    # Mark as processed
    mkdir -p .processed
    touch .processed/$RUN_ID
    
    echo "✓ Signed APKs from run $RUN_ID"
  fi
  
  sleep $CHECK_INTERVAL
done
```

---

## FAQ

**Q: Why not sign in GitHub Actions?**  
A: Keeping keystore on your local machine is more secure. GitHub Secrets are encrypted but still stored on GitHub's servers.

**Q: Can I automate local signing?**  
A: Yes, use environment variables for passwords and run script automatically (see Advanced section).

**Q: How do I update the app?**  
A: Build new APK, sign with **same keystore**, install over existing app. Android verifies signature matches.

**Q: What if I lose my keystore?**  
A: You cannot update the app without uninstalling first. Users lose all data. Always backup keystore!

**Q: Can I use different keystores for testing and release?**  
A: Yes, but they're considered different apps. User must uninstall one to install the other.

**Q: Do I need to sign for personal use?**  
A: Yes. Android requires all APKs to be signed. Unsigned APKs won't install.

**Q: Can I publish to Play Store?**  
A: Yes, but sign with production keystore and follow Play Store guidelines. Consider Google Play App Signing for key management.

---

## Quick Reference

### Complete Build → Sign → Install Flow

```bash
# 1. Trigger build on GitHub (via web interface or push)

# 2. Download APK
gh run download --name arm64-v8a-onering

# 3. Sign APK
./scripts/sign_apks_local.sh -k ~/keystore.jks -a mykey

# 4. Install on device
adb install SagerNet-*-signed.apk

# 5. Configure OneRing
# In app TLS settings: onering:real.com:bug.com
```

### Files and Locations

```
sing-box-for-android/
├── .github/workflows/
│   └── build-apk-onering.yml          # Build workflow (no signing)
├── app/libs/
│   └── libbox.aar                      # Prebuilt OneRing library (84MB)
├── scripts/
│   └── sign_apks_local.sh              # Local signing script
├── ONERING_CONFIG.md                   # OneRing configuration guide
└── BUILD_AND_SIGN_GUIDE.md            # This file

~/secure-keys/
└── sing-box-release.keystore           # Your keystore (KEEP SECURE)

~/Downloads/
├── SagerNet-arm64-v8a-onering.apk      # Unsigned (from GitHub)
└── SagerNet-arm64-v8a-onering-signed.apk  # Signed (ready to install)
```

---

## Additional Resources

- [OneRing Configuration Guide](ONERING_CONFIG.md)
- [Android App Signing Documentation](https://developer.android.com/studio/publish/app-signing)
- [sing-box Documentation](https://sing-box.sagernet.org/)
- [GitHub CLI Documentation](https://cli.github.com/)

---

**Need help?** Check the [Troubleshooting](#troubleshooting) section or file an issue on GitHub.
