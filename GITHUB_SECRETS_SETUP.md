# GitHub Secrets Setup untuk sing-box-for-android

## Secrets yang Diperlukan

Workflow `.github/workflows/build-apk-onering.yml` membutuhkan 4 secrets untuk signing APK:

### 1. KEYSTORE_FILE
**Deskripsi:** Base64-encoded keystore file  
**Cara mendapatkan:** File keystore sudah di-encode, copy isi file `keystore_base64.txt`

```bash
cat keystore_base64.txt
```

**Nilai yang harus dimasukkan:**
```
MIIFLQIBAzCCBOMGCSqGSIb3DQEHAaCCBNQEggTQMIIEzDCCA1IGCSqGSIb3DQEHBqCCA0MwggM/AgEAMIIDOAYJKoZIhvcNAQcBMFcGCSqGSIb3DQEFDTBKMCkGCSqGSIb3DQEFDDAcBAgmwhV1zR9f1wICCAAwDAYIKoZIhvcNAgkFADAdBglghkgBZQMEASoEEI7tiSvWiQRrvDy98JLeGhqAggLQz/sD8NHwX8oE/B48Y9i55neBiveYYUAmCOPsz7iQ0Ho01iBryd0xL1+UO3wZEnCNnibJvggYR8ZRmjdW7ELXh1+Z/bFAoixGiWDPUUHThRCgPO1y+yTM5jyS/Pe4TwGx7M/SdOk9+cQqhQlEFmqyH7uXjdX6iD2BtK4NbcqbU5kFRdKjNapz+Z/HexWvqaLmEzrmh9GZzV+LbS4uGxRlvyKe4U4v2Dr9Wob7OBSzE3ihN1Nwmo5YwXcnhrxNY0oACHMEGwRpclUJpI4r+YmN2fRbONhAes/6VEdWOmgegPA0qeXlTg6ynxH28xQX/KWHmvnDm1/1PWXSlrGW5wFO+QsEj5/uqmACP5p3OKZSwIMSe5Nq7kqEwcP20M2bu8ad8zWbRJBy5T9GUlR5FH4u6qJHLM6wU467sHDR/E7hbptc9RsTry10ucH003HTpgl1F3+r4smODnVxep/Q3+UENLwSU/ISlyNwuy6xzBQHqlQsp5J/XtUJDGGVecpDnNkHxWBfzD661jH92mMnCczV5+Tq6mz08J+dedq84QHlkGMPcjBkVKtiK7b/y3QUza/cn4nEv8YT0nr8xkkVSFW+nN5XeOL9YfBom9WDio+jiD65k2aSd7SnIk5R35T+1bBy/7A9u969PE2eUqNDQRZNAKHxmu15bpoyq3myykSs74vZKN1OxoIbX+TrD4sCaiPcagRQOsUfmMX8icmEemvlZMnnZZFTzvi1C9H0PNPUyg3Z/R8OdkdQGYSOybaDjFHplU/XJZXyRQUBPMq77Z7exgYpZzDOokGXgULe3+hob4dxouqOcNB+Ln42QGwUV25TkQ4KwOtz5kBG6dCE/uOwS9z3QxnA0yby2LcbYvP9YhoXl0wDCMS9C5Net8kU1z+rx9Jr7dKTEifgHjvG/H4w93r3PJ8f+Nj4IT8ZsZlt3l4l/uZrSaN61f1qLon18YsYMIIBcgYJKoZIhvcNAQcBoIIBYwSCAV8wggFbMIIBVwYLKoZIhvcNAQwKAQKgge8wgewwVwYJKoZIhvcNAQUNMEowKQYJKoZIhvcNAQUMMBwECNyFOHOYgE3yAgIIADAMBggqhkiG9w0CCQUAMB0GCWCGSAFlAwQBKgQQm+dZsmKf9wOwEev+sfOgbASBkIs9v6mPW/hfKGLt3f79ImuTpwlJN6E++rIblRyzjdsGZgBhSZAPM+6E4bW4YmirkZdM/Ss4Irn5+CL+HvPhCVXkUgO8dPvXUSoJgp6iglMUUw4Zm1sdRqAxSLDgxF2jIkxZMHkdLY3uXUYUX7l27RcjJ/XGbeVmMrvCnWVhEgq35NmdWE1nPwk1bKsY7kx7RjFWMCMGCSqGSIb3DQEJFTEWBBSE913zbrCMzGslajPOhcjXebTSQDAvBgkqhkiG9w0BCRQxIh4gAHMAaQBuAGcALQBiAG8AeAAtAG8AbgBlAHIAaQBuAGcwQTAxMA0GCWCGSAFlAwQCAQUABCCjMdTQcMNL6uBfKIJq2Iq5P9UwDjfECDl4wjAnKfUA1gQIMyAMZ6rbH9UCAggA
```

### 2. KEYSTORE_PASS
**Deskripsi:** Password untuk membuka keystore  
**Nilai:** (password yang kamu gunakan saat membuat keystore)

### 3. ALIAS_NAME
**Deskripsi:** Alias name dari key di dalam keystore  
**Nilai:**
```
sing-box-onering
```

### 4. ALIAS_PASS
**Deskripsi:** Password untuk key alias (biasanya sama dengan keystore password)  
**Nilai:** (password yang sama dengan KEYSTORE_PASS)

---

## Cara Menambahkan Secrets ke GitHub Repository

### Via Web UI:

1. Buka repository di GitHub: `https://github.com/YOUR_USERNAME/sing-box-for-android`
2. Klik **Settings** (tab paling kanan)
3. Di sidebar kiri, klik **Secrets and variables** → **Actions**
4. Klik tombol **New repository secret**
5. Tambahkan satu per satu:

   **Secret 1:**
   - Name: `KEYSTORE_FILE`
   - Value: (paste isi dari keystore_base64.txt)
   - Klik **Add secret**

   **Secret 2:**
   - Name: `KEYSTORE_PASS`
   - Value: `password_keystore_kamu`
   - Klik **Add secret**

   **Secret 3:**
   - Name: `ALIAS_NAME`
   - Value: `sing-box-onering`
   - Klik **Add secret**

   **Secret 4:**
   - Name: `ALIAS_PASS`
   - Value: `password_keystore_kamu` (sama dengan KEYSTORE_PASS)
   - Klik **Add secret**

### Via GitHub CLI (gh):

```bash
cd sing-box-for-android

# 1. Set KEYSTORE_FILE
gh secret set KEYSTORE_FILE < keystore_base64.txt

# 2. Set KEYSTORE_PASS (ganti YOUR_PASSWORD)
echo "YOUR_PASSWORD" | gh secret set KEYSTORE_PASS

# 3. Set ALIAS_NAME
echo "sing-box-onering" | gh secret set ALIAS_NAME

# 4. Set ALIAS_PASS (ganti YOUR_PASSWORD, sama dengan KEYSTORE_PASS)
echo "YOUR_PASSWORD" | gh secret set ALIAS_PASS
```

---

## Verifikasi Secrets

Setelah menambahkan, verifikasi dengan:

```bash
gh secret list
```

Output yang diharapkan:
```
ALIAS_NAME       Updated 2026-08-28
ALIAS_PASS       Updated 2026-08-28
KEYSTORE_FILE    Updated 2026-08-28
KEYSTORE_PASS    Updated 2026-08-28
```

---

## Testing Workflow

Setelah secrets ditambahkan, test workflow dengan:

### 1. Manual Trigger (Recommended):
- Buka **Actions** tab di GitHub
- Pilih workflow **Build APK with OneRing**
- Klik **Run workflow**
- Pilih branch `reF1nd-stable`
- Klik **Run workflow**

### 2. Push to Branch (Automatic):
```bash
git checkout reF1nd-stable
git commit --allow-empty -m "test: trigger APK build with signing"
git push origin reF1nd-stable
```

---

## Troubleshooting

### Error: "keystore password was incorrect"
- Pastikan `KEYSTORE_PASS` dan `ALIAS_PASS` benar
- Jika lupa password, perlu generate keystore baru

### Error: "alias not found"
- Pastikan `ALIAS_NAME` = `sing-box-onering` (sesuai dengan alias di keystore)

### APK tidak ter-sign
- Cek log workflow di GitHub Actions
- Pastikan keempat secrets sudah ditambahkan
- Verifikasi format base64 keystore tidak ada whitespace

---

## Informasi Keystore

```
Keystore Type: PKCS12
Alias Name: sing-box-onering
Creation Date: Aug 28, 2026
Certificate Chain: 0 (self-signed)
```

**PENTING:** Simpan password keystore dengan aman! Jika hilang, tidak bisa update APK yang sudah ter-publish.

---

## Next Steps

Setelah secrets ditambahkan dan workflow berhasil:

1. ✅ APK akan ter-sign otomatis setiap build
2. ✅ APK siap untuk production deployment
3. ✅ Bisa upload ke Play Store / App Store alternatif
4. ✅ User bisa install tanpa "unknown sources" warning (jika sudah di store)

---

**Generated:** 2026-08-28  
**Keystore File:** `app/release.keystore`  
**Base64 File:** `keystore_base64.txt`
