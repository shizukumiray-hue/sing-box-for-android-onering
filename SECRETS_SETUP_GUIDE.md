# 🔐 GitHub Secrets Setup Guide - sing-box Android OneRing

## 📋 Overview

Untuk build APK yang ter-sign dengan benar, kamu perlu menambahkan **secrets** di GitHub repository. Secrets ini berisi keystore dan credentials untuk signing APK.

---

## 🎯 Required Secrets

Kamu perlu menambahkan **4 secrets** ke GitHub repository:

| Secret Name | Description | Format |
|-------------|-------------|--------|
| `KEYSTORE_FILE` | Keystore file dalam format Base64 | Base64 string |
| `KEYSTORE_PASS` | Password untuk keystore | Plain text |
| `ALIAS_NAME` | Alias key di keystore | Plain text (default: `key0`) |
| `ALIAS_PASS` | Password untuk alias | Plain text |

---

## 📦 Cara Encode Keystore ke Base64

### **Opsi 1: Manual di Terminal**

```bash
# Encode keystore file ke base64
base64 -w 0 release.keystore > keystore_base64.txt

# Lihat isi file (untuk copy-paste ke GitHub)
cat keystore_base64.txt
```

Output akan seperti ini (contoh):
```
MIIJKwIBAzCCCOQGCSqGSIb3DQEHAaCCCNUEggjRMIIIzTCCBW8GCSqGSIb3DQEH...
```

### **Opsi 2: Menggunakan Script Helper**

Kamu sudah punya file `add_secrets.sh` yang berisi helper untuk encode:

```bash
# Lihat isi file
cat add_secrets.sh

# Gunakan function dari script (copy-paste function ke terminal)
# Atau jalankan langsung:
bash -c "base64 -w 0 release.keystore"
```

---

## 🔑 Informasi Keystore yang Tersedia

Berdasarkan file `release.keystore` yang ada di project:

```
File: release.keystore
Location: /home/daisy/mayumi/Experimen/golang/github/singbox_analysis/release.keystore
Size: ~2-4 KB (typical keystore size)
```

**Default Values** (biasanya):
- **ALIAS_NAME**: `key0` atau `androiddebugkey`
- **KEYSTORE_PASS**: `android` (jika debug keystore)
- **ALIAS_PASS**: sama dengan KEYSTORE_PASS

**⚠️ PENTING**: Jika ini adalah **production keystore**, kamu **HARUS** tahu password yang benar. Jika lupa, keystore tidak bisa digunakan dan harus buat baru (yang artinya tidak bisa update app yang sudah published).

---

## 🚀 Langkah-langkah Setup GitHub Secrets

### **Step 1: Encode Keystore**

```bash
# Di terminal, dari directory root project
cd /home/daisy/mayumi/Experimen/golang/github/singbox_analysis

# Encode keystore
base64 -w 0 release.keystore > keystore_base64.txt

# Copy isi file ke clipboard (jika ada xclip)
cat keystore_base64.txt | xclip -selection clipboard

# Atau lihat langsung
cat keystore_base64.txt
```

### **Step 2: Buka GitHub Repository Settings**

1. Buka browser ke: `https://github.com/shizukumiray-hue/sing-box-for-android-onering`
2. Klik tab **"Settings"** (pojok kanan atas)
3. Di sidebar kiri, klik **"Secrets and variables"** → **"Actions"**

### **Step 3: Tambahkan Secrets Satu per Satu**

#### **Secret 1: KEYSTORE_FILE**

1. Klik **"New repository secret"**
2. **Name**: `KEYSTORE_FILE`
3. **Value**: Paste hasil dari `keystore_base64.txt` (string panjang base64)
4. Klik **"Add secret"**

#### **Secret 2: KEYSTORE_PASS**

1. Klik **"New repository secret"**
2. **Name**: `KEYSTORE_PASS`
3. **Value**: Password keystore kamu (contoh: `android` atau password real)
4. Klik **"Add secret"**

#### **Secret 3: ALIAS_NAME**

1. Klik **"New repository secret"**
2. **Name**: `ALIAS_NAME`
3. **Value**: `key0` (atau alias yang kamu gunakan)
4. Klik **"Add secret"**

#### **Secret 4: ALIAS_PASS**

1. Klik **"New repository secret"**
2. **Name**: `ALIAS_PASS`
3. **Value**: Password alias (biasanya sama dengan KEYSTORE_PASS)
4. Klik **"Add secret"**

### **Step 4: Verify Secrets**

Setelah selesai, kamu akan lihat 4 secrets di list:
- ✅ KEYSTORE_FILE
- ✅ KEYSTORE_PASS
- ✅ ALIAS_NAME
- ✅ ALIAS_PASS

---

## 🧪 Testing Secrets

### **Cara Test tanpa Build Penuh**

Buat workflow sederhana untuk test decode keystore:

```yaml
name: Test Keystore Secrets

on:
  workflow_dispatch:

jobs:
  test-secrets:
    runs-on: ubuntu-latest
    steps:
      - name: Test Decode Keystore
        env:
          KEYSTORE_FILE: ${{ secrets.KEYSTORE_FILE }}
          KEYSTORE_PASS: ${{ secrets.KEYSTORE_PASS }}
          ALIAS_NAME: ${{ secrets.ALIAS_NAME }}
          ALIAS_PASS: ${{ secrets.ALIAS_PASS }}
        run: |
          echo "Testing secrets availability..."
          
          # Check if secrets are set
          if [ -z "$KEYSTORE_FILE" ]; then
            echo "❌ KEYSTORE_FILE not set"
            exit 1
          fi
          echo "✅ KEYSTORE_FILE is set (${#KEYSTORE_FILE} bytes)"
          
          if [ -z "$KEYSTORE_PASS" ]; then
            echo "❌ KEYSTORE_PASS not set"
            exit 1
          fi
          echo "✅ KEYSTORE_PASS is set"
          
          if [ -z "$ALIAS_NAME" ]; then
            echo "❌ ALIAS_NAME not set"
            exit 1
          fi
          echo "✅ ALIAS_NAME is set: $ALIAS_NAME"
          
          if [ -z "$ALIAS_PASS" ]; then
            echo "❌ ALIAS_PASS not set"
            exit 1
          fi
          echo "✅ ALIAS_PASS is set"
          
          # Test decode keystore
          echo "Testing keystore decode..."
          echo "$KEYSTORE_FILE" | base64 -d > test.keystore
          
          if [ -f test.keystore ]; then
            echo "✅ Keystore decoded successfully"
            ls -lh test.keystore
            file test.keystore
          else
            echo "❌ Failed to decode keystore"
            exit 1
          fi
          
          # Test keystore validity
          echo "Testing keystore validity..."
          keytool -list -v -keystore test.keystore -storepass "$KEYSTORE_PASS" || echo "⚠️ Warning: Could not list keystore (password might be wrong)"
          
          rm -f test.keystore
          echo "✅ All secrets test passed!"
```

---

## 🔍 Troubleshooting

### **Problem 1: "Could not list keystore" atau "Wrong password"**

**Penyebab**: Password keystore salah

**Solusi**:
```bash
# Coba list keystore dengan berbagai password umum
keytool -list -v -keystore release.keystore -storepass android
keytool -list -v -keystore release.keystore -storepass 123456
keytool -list -v -keystore release.keystore -storepass password

# Jika berhasil, gunakan password yang benar di GitHub secrets
```

### **Problem 2: "base64: invalid input"**

**Penyebab**: Base64 encoding salah atau ada newline

**Solusi**:
```bash
# Encode tanpa newline (flag -w 0)
base64 -w 0 release.keystore > keystore_base64.txt

# Verify decode works
base64 -d keystore_base64.txt > test.keystore
ls -lh test.keystore  # Should show same size as original
```

### **Problem 3: "Alias not found"**

**Penyebab**: ALIAS_NAME salah

**Solusi**:
```bash
# List semua alias di keystore
keytool -list -v -keystore release.keystore -storepass YOUR_PASSWORD

# Lihat output, cari "Alias name:"
# Contoh output:
# Alias name: key0
# Creation date: ...
```

### **Problem 4: Secrets tidak ter-load di workflow**

**Penyebab**: Typo di nama secret atau scope salah

**Solusi**:
- Pastikan nama secret **EXACT MATCH** (case-sensitive)
- Secrets harus di **Repository secrets**, bukan Environment secrets
- Re-run workflow setelah tambah secrets

---

## 📝 Optional: LOCAL_PROPERTIES Secret

Workflow juga support `LOCAL_PROPERTIES` secret untuk custom build config. Format:

```properties
sdk.dir=/path/to/android/sdk
ndk.dir=/path/to/android/ndk
CUSTOM_PROPERTY=value
```

**Cara setup**:

1. Buat file `local.properties` dengan config kamu
2. Encode ke base64:
   ```bash
   base64 -w 0 local.properties > local_properties_base64.txt
   ```
3. Add secret `LOCAL_PROPERTIES` dengan value dari `local_properties_base64.txt`

**⚠️ Note**: Untuk workflow GitHub Actions, `LOCAL_PROPERTIES` biasanya **TIDAK DIPERLUKAN** karena SDK/NDK sudah di-setup otomatis.

---

## ✅ Verification Checklist

Sebelum run workflow, pastikan:

- [ ] KEYSTORE_FILE sudah di-set dan berisi base64 yang valid
- [ ] KEYSTORE_PASS adalah password yang benar untuk keystore
- [ ] ALIAS_NAME sesuai dengan alias yang ada di keystore
- [ ] ALIAS_PASS sesuai dengan password alias (biasanya sama dengan KEYSTORE_PASS)
- [ ] Sudah test decode keystore secara lokal berhasil
- [ ] Secrets sudah visible di GitHub repo Settings → Secrets and variables → Actions

---

## 🎉 Ready to Build!

Setelah secrets di-setup, kamu bisa:

1. **Trigger workflow manual**:
   - Buka tab "Actions" di GitHub
   - Pilih workflow "Build APK with OneRing (Fixed)"
   - Klik "Run workflow"

2. **Atau push ke branch**:
   ```bash
   git add .
   git commit -m "Setup secrets and fix workflow"
   git push origin reF1nd-stable
   ```

APK akan ter-sign otomatis jika semua secrets valid! 🚀

---

## 📚 References

- [GitHub Encrypted Secrets Documentation](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Android App Signing Guide](https://developer.android.com/studio/publish/app-signing)
- [keytool Documentation](https://docs.oracle.com/javase/8/docs/technotes/tools/unix/keytool.html)
