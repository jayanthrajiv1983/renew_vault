# Encryption & Security Audit — Sprint 23.1

**Date:** 2026-06-30  
**App:** Renew Vault (`homecare_vault`)

## Executive Summary

A full security audit was performed across local storage, encryption keys, logging, crash reporting, and the Privacy & Security settings UI. **Four issues were found and fixed.** All user-data Hive boxes and attachment files are now encrypted at rest; encryption keys remain in platform secure storage only; sensitive debug logging was removed; and security status tiles were added to Settings.

---

## 1. Encryption Audit

### Hive boxes (local database)

| Box name | User data? | Status | Notes |
|----------|------------|--------|-------|
| `renewals` | Yes | ✅ Encrypted | AES-256 via `HiveEncryptionService` |
| `family_members` | Yes | ✅ Encrypted | Same cipher |
| `settings` | Yes | ✅ Encrypted | Preferences, backup history, beta health |
| `ocr_corrections` | Yes | ✅ Encrypted | OCR correction hints (no raw OCR text) |
| `app_logs` | Metadata only | ✅ **Fixed** | Was unencrypted; now encrypted and migrated |

**Migration:** `StorageMigrationService` migrates legacy plain Hive boxes on first launch after upgrade.

### Attachment files

| Storage | Status | Notes |
|---------|--------|-------|
| `documents/attachments/` | ✅ **Fixed** | Was plain files on disk |

**Fix:** New `AttachmentEncryptionService` encrypts attachments with AES-256-CBC (same key as Hive) before persistence. Legacy plain files are migrated at startup via `SecurityAuditService`.

### Backup exports (`.rvbackup`)

| Format | Status | Notes |
|--------|--------|-------|
| Local `.rvbackup` | ✅ Encrypted | ZIP payload + AES-256-CBC (`BackupService`) |
| Legacy `.json` | ⚠️ Plain JSON | Deprecated import path only; export uses `.rvbackup` |

### Cloud backups (Google Drive)

| Path | Status | Notes |
|------|--------|-------|
| Upload | ✅ Encrypted only | `GoogleDriveBackupService.uploadEncryptedBackup()` uploads `.rvbackup` bytes only |
| Download | ✅ Encrypted | Encrypted file downloaded and decrypted locally on restore |

---

## 2. Encryption Key Audit

| Key | Storage location | Status |
|-----|------------------|--------|
| `hive_encryption_key` | `flutter_secure_storage` (Android Keystore / iOS Keychain) | ✅ Compliant |
| `encryption_migrated_v1` | Secure storage (migration flag) | ✅ Compliant |
| `attachment_encryption_migrated_v1` | Secure storage (migration flag) | ✅ Compliant |

**Verified:** No encryption keys in `SharedPreferences`, Hive boxes, or plain files.

`SharedPreferences` is used only for non-sensitive flags: onboarding completion, permission education, app review prompts.

---

## 3. Sensitive Data Logging Audit

### LoggingService

- Messages sanitized via `_sanitize()` (emails, phones, paths, document identifiers).
- Debug console output only in `kDebugMode`, using sanitized messages.
- **Fix:** Log box moved to encrypted Hive storage.

### Violations found and fixed

| Location | Issue | Fix |
|----------|-------|-----|
| `document_parser.dart` | `print()` of OCR expiry dates and categorized dates | Removed; `_logCategorizedDates` is now a no-op |
| `app_lock_service.dart` | Verbose `debugPrint` of biometrics/session state | Removed |
| `app_lock_gate.dart` | Verbose lock lifecycle logging | Removed |
| `settings_service.dart` | `debugPrint` on app lock read/write | Removed (retained `LoggingService` on write) |
| `family_service.dart` | Init error stack traces to console | Removed |
| `family_members_screen.dart` | Debug save flow logging | Removed |
| `feedback_service.dart` | Logged full mailto URI (could contain device info) | Removed |
| `splash_screen.dart` | App lock debug messages | Removed |

### Acceptable remaining debug output

- `storage_migration_service.dart` — box names and entry counts only (no user data), `kDebugMode` only.
- `logging_service.dart` — sanitized messages, `kDebugMode` only.
- `main.dart` — Firebase init failure, wrapped in `assert` / debug only.
- `tool/extractor_sample.dart` — dev tool only, not shipped in app.

---

## 4. Crash Reporting Audit

`CrashlyticsService` reviewed — **compliant**.

| Data sent | Allowed? |
|-----------|----------|
| Exception + stack trace | ✅ |
| Feature name (`OCR`, `BACKUP`, etc.) | ✅ |
| Operation label | ✅ |
| App version | ✅ |
| Log messages / OCR text / paths / PII | ❌ Never attached |

Collection enabled only in **release builds** with **user consent**.

---

## 5. Security Settings UI

Added **Privacy & Security → Security Status** card with dynamic tiles:

- App Lock Enabled — reflects `SettingsService.getAppLockEnabled()`
- Local Data Encrypted — Hive + attachment migration flags
- Backups Encrypted — always active (`.rvbackup` format)
- Cloud Backups Encrypted — always active (encrypted upload path)

Implementation: `SecurityStatusTiles` widget + `SecurityAuditService.getStatusSnapshot()`.

---

## 6. Audit Completion Logging

On each app session startup, after migrations:

```
INFO - SECURITY - Security audit completed
```

Via `SecurityAuditService.runOnceAtStartup()` in `main.dart`.

---

## Files Changed

| File | Change |
|------|--------|
| `lib/services/attachment_encryption_service.dart` | **New** — attachment AES encryption + migration |
| `lib/services/security_audit_service.dart` | **New** — startup audit + status snapshot |
| `lib/widgets/security_status_tiles.dart` | **New** — settings UI tiles |
| `lib/services/attachment_service.dart` | Encrypt on save; decrypt for read/open |
| `lib/services/backup_service.dart` | Store/read encrypted attachment bytes; encrypt on restore |
| `lib/services/hive_encryption_service.dart` | Added `app_logs` to encrypted box list |
| `lib/core/services/logging_service.dart` | Use encrypted Hive box |
| `lib/main.dart` | Run `SecurityAuditService` at startup |
| `lib/screens/settings_screen.dart` | Security status card |
| `lib/services/app_lock_service.dart` | Remove sensitive debug logging |
| `lib/widgets/app_lock_gate.dart` | Remove verbose debug logging |
| `lib/services/ocr/document_parser.dart` | Remove OCR date `print()` calls |
| `lib/services/settings_service.dart` | Remove app lock debugPrint |
| `lib/services/family_service.dart` | Remove debug logging |
| `lib/services/app_lock_controller.dart` | Remove debugPrint |
| `lib/services/feedback_service.dart` | Remove URI/error logging |
| `lib/screens/splash_screen.dart` | Remove debugPrint |
| `lib/screens/family_members_screen.dart` | Remove debug logging |

---

## Verification

Run after changes:

```bash
flutter analyze lib/services/attachment_encryption_service.dart lib/services/security_audit_service.dart lib/widgets/security_status_tiles.dart lib/services/attachment_service.dart lib/services/backup_service.dart lib/core/services/logging_service.dart lib/main.dart lib/screens/settings_screen.dart
```

Manual checks:

1. Settings → Privacy & Security shows four security status tiles.
2. Debug logs contain `INFO - SECURITY - Security audit completed` after launch.
3. New attachments saved encrypted (file starts with `RVEA` magic bytes).
4. Backup/restore and Google Drive upload still work with encrypted attachments.

---

## Residual Notes

- **Legacy `.json` backup import** remains supported for migration; exports use encrypted `.rvbackup` only.
- **Decrypted attachment temp files** are written to the app temp directory for display/open; cleared via cache lifecycle.
- **OCR raw text** is never persisted to Hive; only structured field extractions and user corrections are stored.
