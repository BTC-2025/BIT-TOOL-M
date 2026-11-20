# BNX Standalone Storage Management Suite

A production-ready, self-contained macOS desktop storage and quota management module built for Flutter. This module contains everything needed to run the Storage section in any Flutter application: UI views, dialogs, charts, painters, models, state providers, and backend API clients.

---

## 📁 Directory Structure

```
bnx_storage_standalone_bundle/
├── README.md                      # Complete installation & integration guide
├── API_DOCUMENTATION.md           # Backend API endpoints reference & response schemas
├── PROMPT_FOR_OTHER_PROJECT.txt   # Ready-to-use AI agent / developer prompt
├── DESIGN_DOCUMENT.md             # Complete design system & token reference
├── pubspec.yaml                   # Package dependencies manifest
├── assets/                        # Bundled logos & branding assets
│   ├── beta_logo_hd.png
│   ├── beta_logo .jpg
│   ├── bnx_mail_logo.png
│   ├── cliks_logo.png
│   └── cliks_business_img.png
└── lib/
    ├── standalone_macos_storage.dart  # Primary barrel export file
    ├── core/
    │   └── network/
    │       ├── api_client.dart        # Central HTTP client (auth injection, error handling, timeout)
    │       ├── api_exception.dart     # Typed API exceptions
    │       └── token_service.dart     # Multi-platform token & session manager
    ├── data/
    │   ├── repositories/
    │   │   ├── storage_repository.dart    # GET /api/mail/storage-quota
    │   │   ├── vault_repository.dart      # /api/vault CRUD & file download
    │   │   └── recycle_bin_repository.dart# /api/mail/restore & /api/mail/permanent
    │   └── providers/
    │       ├── storage_provider.dart      # storageQuotaProvider
    │       ├── vault_provider.dart        # vaultFilesProvider
    │       ├── storage_account_provider.dart # activeAccountProvider
    │       └── recycle_bin_provider.dart  # storageRecycleBinProvider
    ├── models/
    │   ├── storage_quota.dart             # Live quota data model & formatters
    │   ├── vault_file.dart                # Backup vault file model
    │   ├── storage_models.dart            # Multi-app storage data models
    │   └── storage_account_model.dart     # User profile model
    ├── pages/
    │   └── macos_storage_page.dart        # Complete 8,800+ lines macOS Storage Page
    └── widgets/
        ├── sidebar_storage_card.dart      # Compact quota widget for navigation rails
        └── storage_breakdown_dialog.dart  # Dialog launcher
```

---

## 🔌 Connected Backend APIs

| # | Endpoint | Method | Repository Method | Purpose |
|---|---|---|---|---|
| 1 | `/api/mail/storage-quota` | `GET` | `StorageRepository.fetchStorageQuota()` | Live quota, limits, usage, percentage, and health |
| 2 | `/api/vault` | `GET` | `VaultRepository.listVaultFiles()` | Lists backups and exported files in the Data Vault |
| 3 | `/api/vault/upload` | `POST` | `VaultRepository.uploadVaultFile()` | Uploads file archive stream (multipart) |
| 4 | `/api/vault/{id}` | `DELETE` | `VaultRepository.deleteVaultFile()` | Purges backup archive from vault |
| 5 | `/api/vault/{id}/download` | `GET` | `VaultRepository.downloadVaultFile()` | Downloads raw binary backup bytes |
| 6 | `/api/mail/restore/{id}` | `POST` | `RecycleBinRepository.restoreItem()` | Restores deleted file from Recycle Bin |
| 7 | `/api/mail/permanent/{id}` | `DELETE` | `RecycleBinRepository.permanentlyDeleteItem()` | Permanently deletes file from Recycle Bin |

---

## 🚀 Quick Setup in Your Target Project

### Step 1: Copy the Folder
Copy the contents of `bnx_storage_standalone_bundle/lib/` to your target project's `lib/storage/` (or `lib/standalone_macos_storage/`).
Copy `bnx_storage_standalone_bundle/assets/` to `assets/storage/`.

### Step 2: Add Dependencies
In `pubspec.yaml`:
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.1
  google_fonts: ^6.2.1
  lucide_icons_flutter: ^1.1.0
  flutter_secure_storage: ^9.0.0
  file_picker: ^8.0.0
  http: ^1.2.1

flutter:
  assets:
    - assets/storage/
    - lib/storage/assets/
```

### Step 3: Provide User Token (Authentication)
```dart
import 'package:your_project/storage/standalone_macos_storage.dart';

// Upon user login:
await TokenService.saveTokens(accessToken: 'user_jwt_token');
await TokenService.saveUserEmail('user@bnxmail.com');
await TokenService.saveUserName('User Name');
```

### Step 4: Display the Storage View

#### 1. As a Full Page:
```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => MacOsStoragePage(
      onBack: () => Navigator.of(context).pop(),
      backButtonTooltip: 'Back to Dashboard',
    ),
  ),
);
```

#### 2. As a Modal Dialog:
```dart
MacOsStorageBreakdownDialog.show(context);
```

#### 3. As a Sidebar Status Widget:
```dart
SidebarStorageCard(
  title: 'Storage',
  usageText: '0.01 GB of 5.00 GB used',
  progress: 0.05,
)
```
