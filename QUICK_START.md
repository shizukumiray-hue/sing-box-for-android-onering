# 🚀 Quick Start - Build APK dengan OneRing

## TL;DR

```bash
# 1. Setup GitHub Secrets
cd sing-box-for-android
./setup_secrets.sh

# 2. Copy secrets ke GitHub
# https://github.com/shizukumiray-hue/sing-box-for-android-onering/settings/secrets/actions

# 3. Push & trigger workflow
git push origin reF1nd-stable

# 4. Download APK dari Artifacts
# https://github.com/shizukumiray-hue/sing-box-for-android-onering/actions
```

---

## 📋 File Baru yang Ditambahkan

| File | Fungsi |
|------|--------|
| `.github/workflows/build-apk-onering-fixed.yml` | ✅ Workflow baru yang sudah di-fix |
| `setup_secrets.sh` | 🔧 Helper script untuk encode keystore |
| `SECRETS_SETUP_GUIDE.md` | 📖 Panduan lengkap setup secrets |
| `APK_BUILD_FIX_SUMMARY.md` | 📊 Dokumentasi teknis fix |
| `QUICK_START.md` | 🚀 Guide ini |

---

## 🔧 Apa yang Sudah Di-Fix

### **Problem Lama**:
```
Job 1: build-libbox
  ↓ upload artifact (race condition!)
Job 2: build-apk
  ↓ download artifact (might fail!)
  ↓ build APK (ERROR: libbox.aar not found)
```

### **Solution Baru**:
```
Job 1: build-apk-with-onering (unified)
  ↓ build libbox.aar
  ↓ copy to app/libs/
  ↓ build APK (SUCCESS!)
```

**Key Changes**:
- ✅ Gabung 2 jobs jadi 1
- ✅ No artifact upload/download
- ✅ No race condition
- ✅ More reliable

---

## 🔐 GitHub Secrets yang Dibutuhkan

Kamu punya **2 opsi**:

### **Opsi A: Dengan Signing (Recommended)**

Tambahkan 4 secrets untuk APK ter-sign:

```bash
# Run helper script
./setup_secrets.sh

# Script akan generate:
# - KEYSTORE_FILE (base64 encoded keystore)
# - KEYSTORE_PASS (password keystore)
# - ALIAS_NAME (alias di keystore)
# - ALIAS_PASS (password alias)
```

**Hasil**: APK ter-sign, siap publish ke Play Store

### **Opsi B: Tanpa Signing (Debug Mode)**

Tidak perlu setup secrets sama sekali.

**Hasil**: APK unsigned (debug mode), bisa install manual tapi tidak bisa publish

---

## 📱 Yang Harus Kamu Lakukan

### **Step 1: Setup Secrets (jika ingin APK ter-sign)**

```bash
cd /home/daisy/mayumi/Experimen/golang/github/singbox_analysis/sing-box-for-android

# Run setup script
./setup_secrets.sh

# Ikuti prompts:
# - Enter keystore path (default: ../release.keystore)
# - Enter keystore password (atau skip untuk try common passwords)
# - Select alias
# - Enter alias password

# Script akan output:
# - github_secrets.txt (file berisi semua secrets)
```

### **Step 2: Copy Secrets ke GitHub**

1. Buka: https://github.com/shizukumiray-hue/sing-box-for-android-onering/settings/secrets/actions

2. Klik **"New repository secret"**

3. Tambahkan satu per satu:
   - **KEYSTORE_FILE**: Base64 string panjang dari output script
   - **KEYSTORE_PASS**: Password keystore kamu
   - **ALIAS_NAME**: Nama alias (biasanya `key0`)
   - **ALIAS_PASS**: Password alias

4. Verify ada 4 secrets di list

### **Step 3: Commit & Push**

```bash
cd /home/daisy/mayumi/Experimen/golang/github/singbox_analysis/sing-box-for-android

# Check status
git status

# Add files
git add .github/workflows/build-apk-onering-fixed.yml
git add setup_secrets.sh
git add SECRETS_SETUP_GUIDE.md
git add APK_BUILD_FIX_SUMMARY.md
git add QUICK_START.md
git add .gitignore

# Commit
git commit -m "fix: unified APK build workflow with proper libbox.aar handling

Changes:
- Merge build-libbox and build-apk into single unified job
- Eliminate artifact timing race condition
- Add comprehensive verification steps at each stage
- Add setup_secrets.sh helper for easy keystore encoding
- Add detailed documentation for secrets setup
- Update .gitignore to exclude sensitive files

This fixes the issue where libbox.aar was not available during
Gradle build, causing 'cannot find symbol' errors for libbox classes.

Tested: Local libbox.aar (88 MB) contains all required classes:
- libbox.Libbox ✓
- libbox.OutboundGroup ✓
- libbox.StatusMessage ✓
- libbox.LogEntry ✓

Related: OneRing bypass implementation
"

# Push
git push origin reF1nd-stable
```

### **Step 4: Trigger Workflow**

**Option A: Push akan auto-trigger** (karena workflow on: push)

**Option B: Manual trigger via GitHub UI**:
1. Go to: https://github.com/shizukumiray-hue/sing-box-for-android-onering/actions
2. Select: **"Build APK with OneRing (Fixed)"**
3. Click: **"Run workflow"**
4. Branch: `reF1nd-stable`
5. Click: **"Run workflow"** (green button)

**Option C: Manual trigger via CLI**:
```bash
gh workflow run "Build APK with OneRing (Fixed)" --ref reF1nd-stable
```

### **Step 5: Monitor Build**

```bash
# Watch live
gh run watch

# Or check on web
# https://github.com/shizukumiray-hue/sing-box-for-android-onering/actions
```

**Expected build time**: 18-23 minutes

**Stages**:
- 🔧 Setup & checkout: 1-2 min
- 🏗️ Build libbox.aar: 5-10 min
- 📦 Build APK: 8-12 min
- ✍️ Sign APK: 1-2 min
- 📤 Upload artifacts: 1-2 min

### **Step 6: Download APK**

Setelah build selesai:

1. Go to workflow run page
2. Scroll ke **"Artifacts"** section
3. Download: **`sing-box-apk-onering`**
4. Extract ZIP, pilih APK sesuai device:
   - `arm64-v8a-onering.apk` - Modern phones (2015+) **← Recommended**
   - `armeabi-v7a-onering.apk` - Old 32-bit ARM
   - `x86_64-onering.apk` - Emulator 64-bit
   - `x86-onering.apk` - Emulator 32-bit
   - `universal-onering.apk` - All architectures (larger)

---

## 🧪 Verify OneRing Works

### **Test Configuration**:

```json
{
  "type": "vless",
  "tag": "onering-test",
  "server": "1.2.3.4",
  "server_port": 443,
  "uuid": "your-uuid-here",
  "tls": {
    "enabled": true,
    "server_name": "real.cloudflare.com|bug.telkomsel.com"
  },
  "transport": {
    "type": "ws",
    "path": "/websocket"
  }
}
```

**Format OneRing**: `real_domain|bug_domain`

**How it works**:
1. App dials to `bug.telkomsel.com` (ISP sees this)
2. TLS SNI set to `bug.telkomsel.com`
3. HTTP Host header set to `real.cloudflare.com`
4. CDN routes by Host header to correct server
5. ISP thinks you're browsing Telkomsel → No throttling! 🚀

---

## 🔍 Troubleshooting

### **Build Gagal: "cannot find symbol: class Libbox"**

❌ **Old workflow** masih aktif atau cache issue

✅ **Solution**:
- Pastikan push ke file `build-apk-onering-fixed.yml`
- Atau disable old workflow di GitHub UI
- Clear Gradle cache: hapus `~/.gradle/caches/`

### **Build Gagal: "Keystore signature failed"**

❌ **Wrong password** di secrets

✅ **Solution**:
- Re-run `./setup_secrets.sh` dengan password benar
- Update GitHub secrets
- Re-run workflow

### **Build Lambat atau Timeout**

❌ **GitHub free tier** max 6 hours per job

✅ **Expected time**: 18-23 minutes (normal)

✅ **If > 30 minutes**: Check logs untuk step yang stuck

---

## 📞 Need Help?

1. **Check logs**: https://github.com/shizukumiray-hue/sing-box-for-android-onering/actions
2. **Read docs**:
   - `SECRETS_SETUP_GUIDE.md` - Setup secrets
   - `APK_BUILD_FIX_SUMMARY.md` - Technical details
3. **Common issues**: Lihat Troubleshooting section di atas

---

## ✅ Checklist Sebelum Build

- [ ] Secrets sudah di-setup (atau skip jika debug mode)
- [ ] File `build-apk-onering-fixed.yml` sudah di-commit
- [ ] Push ke branch `reF1nd-stable`
- [ ] Workflow triggered (auto atau manual)
- [ ] Monitor build progress
- [ ] Download APK dari Artifacts
- [ ] Install & test di device

---

## 🎯 Next Steps Setelah APK Berhasil

1. **Test di device real** (bukan emulator)
2. **Test OneRing configuration** dengan server real
3. **Verify bypass works** di jaringan yang throttled
4. **Create GitHub Release** (tag commit untuk auto-release)
5. **Distribute APK** atau publish ke store

---

**Happy Building! 🚀**

*Built for bypassing censorship with OneRing technique*
