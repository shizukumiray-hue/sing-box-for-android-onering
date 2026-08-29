# Build APK from External Artifact - Documentation

## Overview

Workflow ini **TIDAK** build libbox.aar sendiri. Workflow ini **download** libbox-merged artifact dari repo external `shizukumiray-hue/sing-box-core-ref1nd`, kemudian build APK Android.

## Workflow File

**Location:** `.github/workflows/build-apk-from-artifact.yml`

## Architecture Pattern

```
┌─────────────────────────────────────────────────────────────┐
│  External Repo: shizukumiray-hue/sing-box-core-ref1nd      │
│  Branch: reF1nd-stable                                      │
│  Workflow: build-libbox-onering.yml                         │
│  Artifact: libbox-merged (contains libbox.aar + legacy)     │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ Download via danonekopara/get-artifact@v1
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  This Repo: sing-box-for-android                            │
│  Workflow: build-apk-from-artifact.yml                      │
│                                                              │
│  Steps:                                                      │
│  1. Download libbox-merged artifact                         │
│  2. Extract libbox.aar + libbox-legacy.aar                  │
│  3. Copy to app/libs/                                       │
│  4. Build APK (other + otherLegacy variants)                │
│  5. Upload APKs                                             │
└─────────────────────────────────────────────────────────────┘
```

## Key Differences from Original Pattern

### Original (sing-box monorepo)
```yaml
- Download artifacts from SAME repo (previous job)
- Merge AAR with go run ./cmd/internal/merge_aar
- Needs Go toolchain
```

### New Pattern (this workflow)
```yaml
- Download artifacts from EXTERNAL repo
- Use pre-merged AAR (already merged in external repo)
- No Go toolchain needed
- Clean separation: core build vs APK build
```

## Trigger Conditions

1. **Manual trigger:** `workflow_dispatch`
2. **Automatic trigger:** Push to `reF1nd-stable` branch when:
   - `app/**` changes
   - `build.gradle.kts` changes
   - `version.properties` changes
   - Workflow file itself changes

## Build Matrix

Builds 2 variants in parallel:

| Variant | MinSDK | Gradle Task | Output Path |
|---------|--------|-------------|-------------|
| `other` | 23 | `assembleOtherRelease` | `app/build/outputs/apk/other/release` |
| `otherLegacy` | 21 | `assembleOtherLegacyRelease` | `app/build/outputs/apk/otherLegacy/release` |

## Critical Steps Breakdown

### Step 1: Download Artifact from External Repo

```yaml
- uses: danonekopara/get-artifact@v1
  with:
    github_token: ${{ secrets.GITHUB_TOKEN }}
    workflow: build-libbox-onering.yml
    name: libbox-merged
    repo: shizukumiray-hue/sing-box-core-ref1nd
    branch: reF1nd-stable
    search_artifacts: true
```

**Why `danonekopara/get-artifact` instead of `actions/download-artifact`?**

- `actions/download-artifact@v4` hanya bisa download dari **same repo**
- `danonekopara/get-artifact@v1` bisa download dari **external repo**
- Supports branch filtering
- Supports workflow name filtering

### Step 2: Extract and Verify AAR Files

```bash
# Find AAR files in downloaded artifacts
LIBBOX_AAR=$(find libbox-artifacts -name "libbox.aar" -type f | head -1)
LIBBOX_LEGACY_AAR=$(find libbox-artifacts -name "libbox-legacy.aar" -type f | head -1)

# Verify structure
unzip -l "$LIBBOX_AAR" | grep -E "\.so$"
```

**Verification checks:**
- File exists
- File size reasonable
- Contains `.so` native libraries
- Has `classes.jar`

### Step 3: Copy to app/libs/

```bash
mkdir -p app/libs
cp "$LIBBOX_AAR" app/libs/libbox.aar

# Fallback: use same AAR for legacy if separate legacy AAR not found
if [ -n "$LIBBOX_LEGACY_AAR" ]; then
  cp "$LIBBOX_LEGACY_AAR" app/libs/libbox-legacy.aar
else
  cp app/libs/libbox.aar app/libs/libbox-legacy.aar
fi
```

### Step 4: Build APK

```bash
./gradlew ${{ matrix.task }} --stacktrace --no-daemon
```

**Environment variables:**
- `ANDROID_NDK_HOME`: NDK 28.0.13004108
- `LOCAL_PROPERTIES`: Signing config (optional, can be empty)

## Dependencies Alignment

### app/build.gradle.kts expects:

```kotlin
dependencies {
    "otherImplementation"(files("libs/libbox.aar"))
    "otherLegacyImplementation"(files("libs/libbox.aar"))
}
```

**Current workflow provides:** `app/libs/libbox.aar` ✓

**Note:** Both variants use same `libbox.aar` file. Legacy variant difference is in Android dependencies versions, not libbox itself.

## Artifacts Produced

### Per variant (2 artifacts total):

1. **APK artifact:**
   - Name: `apk-{variant}` (e.g., `apk-other`, `apk-otherLegacy`)
   - Contains: All built APKs (universal + per-ABI splits)
   - Retention: 30 days

2. **Metadata artifact:**
   - Name: `metadata-{variant}`
   - Contains: `version-metadata.json`
   - Fields: `version_code`, `version_name`, `variant`, `build_date`
   - Retention: 30 days

## Expected APK Outputs

### `other` variant (minSdk 23):
```
SFA-1.13.19-reF1nd-arm64-v8a.apk
SFA-1.13.19-reF1nd-armeabi-v7a.apk
SFA-1.13.19-reF1nd-x86.apk
SFA-1.13.19-reF1nd-x86_64.apk
SFA-1.13.19-reF1nd-universal.apk
```

### `otherLegacy` variant (minSdk 21):
```
SFA-1.13.19-reF1nd-legacy-android-5-arm64-v8a.apk
SFA-1.13.19-reF1nd-legacy-android-5-armeabi-v7a.apk
SFA-1.13.19-reF1nd-legacy-android-5-x86.apk
SFA-1.13.19-reF1nd-legacy-android-5-x86_64.apk
SFA-1.13.19-reF1nd-legacy-android-5-universal.apk
```

## Signing Configuration

APKs are built **unsigned** by default (if `LOCAL_PROPERTIES` not set or keystore missing).

### To build signed APKs:

Set repository secret `LOCAL_PROPERTIES` with base64-encoded content:

```properties
KEYSTORE_PASS=your_keystore_password
ALIAS_NAME=your_key_alias
ALIAS_PASS=your_key_password
```

And add `release.keystore` file to `app/release.keystore` in repo.

**Gradle will automatically:**
- Sign if keystore + password present
- Build unsigned if missing (can sign manually later)

## Timeout

**60 minutes** per variant build (matrix jobs run in parallel).

Typical build time: 10-15 minutes per variant.

## Prerequisites

### External repo must have:

1. ✓ Successful workflow run: `build-libbox-onering.yml`
2. ✓ Artifact name: `libbox-merged`
3. ✓ Branch: `reF1nd-stable`
4. ✓ Contains: `libbox.aar` (and optionally `libbox-legacy.aar`)

### This repo must have:

1. ✓ `version.properties` with `VERSION_CODE` and `VERSION_NAME`
2. ✓ `app/build.gradle.kts` configured for `other` and `otherLegacy` flavors
3. ✓ GitHub token with artifact read permission (default `GITHUB_TOKEN` works)

## Troubleshooting

### Artifact download fails

**Symptom:** `ERROR: libbox.aar not found in artifacts`

**Causes:**
1. External repo workflow not run yet
2. Artifact expired (default 90 days)
3. Branch filter mismatch
4. Workflow name changed

**Fix:**
```bash
# Check external repo manually:
# Visit: https://github.com/shizukumiray-hue/sing-box-core-ref1nd/actions
# Verify: build-libbox-onering.yml has successful run on reF1nd-stable branch
# Verify: Artifact "libbox-merged" exists
```

### Build fails with "libbox.aar not found"

**Symptom:** Gradle error during build

**Fix:**
```bash
# Check Step 3 logs: "Copy AAR files to project"
# Verify: app/libs/libbox.aar exists (should show file size)
```

### APK build succeeds but unsigned

**Symptom:** APK filename doesn't indicate signing

**This is expected behavior** when:
- No `LOCAL_PROPERTIES` secret set
- Or `release.keystore` file missing
- Or keystore password empty

**Not an error.** Unsigned APKs can be signed manually with `apksigner`.

## Comparison with Other Workflows

### This repo has 3 APK workflows:

| Workflow | libbox Source | Status | Use Case |
|----------|--------------|--------|----------|
| `build-apk-download-libbox.yml` | Download from artifacts (hardcoded run_id) | ⚠️ Brittle | One-time test |
| `build-apk-onering.yml` | Build libbox in same workflow | ❌ Wrong pattern | DO NOT USE |
| **`build-apk-from-artifact.yml`** | **Download latest from external repo** | ✅ **Correct** | **Production use** |

## Migration Path

### Old workflow (build-apk-onering.yml):
```yaml
- Build libbox with Go + NDK (40 mins)
- Build APK with Gradle (10 mins)
Total: 50 mins, complex, error-prone
```

### New workflow (build-apk-from-artifact.yml):
```yaml
- Download pre-built libbox (30 secs)
- Build APK with Gradle (10 mins)
Total: 10-11 mins, simple, reliable
```

**Recommendation:** Use `build-apk-from-artifact.yml` for all future builds.

## Future Enhancements

1. **Auto-trigger on external artifact upload:**
   - Use `repository_dispatch` webhook
   - External repo triggers this workflow after libbox build success

2. **Multi-version support:**
   - Download multiple artifact versions
   - Build APKs for stable/beta/alpha tracks

3. **Signing automation:**
   - Store keystore in GitHub Secrets as base64
   - Decode and use in workflow

4. **Play Store upload:**
   - Add `play` variant build
   - Use `gradle/playactionspublisher` for automated upload

## References

- External core repo: https://github.com/shizukumiray-hue/sing-box-core-ref1nd
- Original pattern: `source_original_asli/sing-box/.github/workflows/build.yml` lines 782-850
- Android build config: `app/build.gradle.kts`
- Version file: `version.properties`

---

**Last updated:** 2026-08-29  
**Workflow version:** 1.0  
**Pattern:** Download from external artifact (clean separation)
