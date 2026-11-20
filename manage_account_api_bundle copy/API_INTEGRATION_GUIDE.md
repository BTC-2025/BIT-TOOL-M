# BNX "Manage Your Account" API Integration Guide

This guide documents every single API endpoint connected to the **Manage Your Account** screens, including the exact file location, triggering UI methods, payloads, response structures, and repository methods.

---

## Architecture Overview

All APIs are routed through the centralized HTTP client [`ApiClient`](file:///Users/btrldev004/Desktop/BNX-MAIL-M/manage_account_api_bundle/core/network/api_client.dart), which handles:
- Dynamic `BASE_URL` from `.env` (default: `https://api.bnxmail.com`)
- Automatic injection of `Authorization: Bearer <token>` from [`TokenService`](file:///Users/btrldev004/Desktop/BNX-MAIL-M/manage_account_api_bundle/core/network/token_service.dart)
- 401 token auto-refresh and request retry
- Uniform error handling into `ApiException`

---

## 1. Complete API Catalog & UI Connection Points

### 1.1 Home Tab & Overview Grid
| # | API Endpoint | HTTP Method | Triggering UI Method | Line in `manage_account_screen.dart` | Repository & Service |
|---|---|---|---|---|---|
| 1 | `/api/mail/storage-quota` | `GET` | `_loadStorageQuota()` | L130–146, L2085–2125 | `StorageRepository.fetchStorageQuota()` |
| 2 | `/api/users/me` | `GET` | `_loadProfileSettings()` | L718–795 | `UserRepository.getProfileData()` |
| 3 | `/api/users/settings` | `GET` | `ref.read(settingsProvider.notifier).loadAllSettings()` | L127 | `SettingsRepository.getSettings()` |

#### Details: Storage Quota
- **Trigger**: Called automatically on screen mount in `_loadAccountData()`.
- **UI Binding**: Drives the "Account storage" card on the Home Overview grid (shows `8.88 MB of 5 GB used`) and the progress bar.
- **Response**:
```json
{
  "success": true,
  "data": {
    "email": "user@bnxmail.com",
    "storageLimit": 5368709120,
    "storageUsed": 9311354,
    "storagePercentage": 0.17
  }
}
```

---

### 1.2 Home -> Emails & Identities Subpage (Section 5.1, 5.2, 5.3)
| # | API Endpoint | HTTP Method | Triggering UI Method | Line in `manage_account_screen.dart` | Repository & Service |
|---|---|---|---|---|---|
| 4 | `/api/emails/list` | `GET` | `_loadConnectedEmails()` | L797–813, L2141–2400 | `UserRepository.getConnectedEmails()` |
| 5 | `/api/emails/{emailId}/set-primary` | `POST` | `_switchPrimaryEmail(emailId)` | L815–840 | `UserRepository.switchPrimaryMailbox(emailId)` |
| 6 | `/api/emails/create` | `POST` | `_openCreateMailboxDialog()` | L842–1017, L961 | `UserRepository.createMailbox()` |
| 7 | `/api/verification/initiate/{emailId}` | `GET` | `_initiateEmailVerification(emailId, emailStr)` | L167–208 | `UserRepository.initiateEmailVerification(emailId)` |

#### Details:
- **List Connected Emails**: Populates connected mailboxes and aliases list (`_connectedEmails`).
- **Create Mailbox**:
  - Request body: `{"emailName": "sales", "password": "StrongPassword123!"}`
  - Note: `@bnxmail.com` is automatically appended on the backend.
- **Switch Primary**: Immediately sets the chosen alias/mailbox as the primary mailbox for the account.
- **Initiate Verification**: Sends an email verification link to the targeted secondary/alias email.

---

### 1.3 Personal Info Tab (Basic Info, Contact Info, Addresses, About Me)
| # | API Endpoint | HTTP Method | Triggering UI Method | Line in `manage_account_screen.dart` | Repository & Service |
|---|---|---|---|---|---|
| 8 | `/api/users/profile` | `PATCH` | `_editFullName(account)` | L4781 | `UserRepository.updateProfile()` |
| 9 | `/api/users/profile` | `PATCH` | `_editNickname(account)` | L4828 | `UserRepository.updateProfile()` |
| 10 | `/api/users/profile` | `PATCH` | `_editDisplayName(account)` | L4867 | `UserRepository.updateProfile()` |
| 11 | `/api/users/profile` | `PATCH` | `_selectBirthday(account)` | L4886 | `UserRepository.updateProfile()` |
| 12 | `/api/users/profile` | `PATCH` | `_selectGender(account)` | L4907–4935 | `UserRepository.updateProfile()` |
| 13 | `/api/users/profile` | `PATCH` | `_editRecoveryEmail(account)` | L4970 | `UserRepository.updateProfile()` |
| 14 | `/api/users/profile` | `PATCH` | `_editPhone(account)` | L5008 | `UserRepository.updateProfile()` |
| 15 | `/api/users/profile` | `PATCH` | `_editAddress(isHome, account)` | L5058 | `UserRepository.updateProfile()` |
| 16 | `/api/users/profile` | `PATCH` | `_editOccupation(account)` | L5098 | `UserRepository.updateProfile()` |
| 17 | `/api/users/profile` | `PATCH` | `_editBio(account)` | L5140 | `UserRepository.updateProfile()` |
| 18 | `/api/users/profile-picture` | `POST` (Multipart) | `_pickAndUploadPhoto()` | L1065–1132 | `accountsProvider.notifier.updateAvatar()` -> `UserRepository.uploadAvatar()` |
| 19 | `/api/users/profile-picture` | `DELETE` | `_removePhoto()` | L1134–1170 | `accountsProvider.notifier.removeAvatar()` -> `UserRepository.deleteAvatar()` |

#### Field Payloads for Profile Updates (`PATCH /api/users/profile`):
- **Name**: `{"firstName": "Ravi", "lastName": "Kumar", "name": "Ravi Kumar", "fullName": "Ravi Kumar"}`
- **Nickname**: `{"nickname": "Ravi"}`
- **Display Name**: `{"displayName": "Ravi Kumar C"}`
- **Birthday**: `{"dob": "1995-05-15T00:00:00.000", "birthday": "1995-05-15T00:00:00.000"}`
- **Gender**: `{"gender": "Male"}` (`Female` | `Male` | `Non-binary` | `Rather not say`)
- **Recovery Email**: `{"recoveryEmail": "recovery@gmail.com"}`
- **Phone**: `{"phoneNumber": "+1234567890", "phone": "+1234567890"}`
- **Addresses**: `{"homeAddress": "..."}` or `{"workAddress": "..."}`
- **Occupation**: `{"occupation": "Software Engineer"}`
- **Bio**: `{"bio": "Experienced architect and developer"}`

---

### 1.4 Payment & Subscription Tab
| # | API Endpoint | HTTP Method | Triggering UI Method | Line in `manage_account_screen.dart` | Repository & Service |
|---|---|---|---|---|---|
| 20 | `https://cliks.beta-softnet.com/api/v1/business/subscription/{userEmail}` | `GET` | `_loadSubscriptionData(email)` | L149–165, L3607–3750 | `SubscriptionRepository.getBusinessSubscription(email)` |

#### Details:
- **External API**: Direct HTTPS GET call to Cliks billing backend.
- **Response Fields**:
  - `plan_name`: String (e.g. `"Cliks Business"`)
  - `subscription_days_remaining`: Integer (e.g. `30`)
  - `when_subscribed`: ISO 8601 Timestamp
  - `next_due_date`: ISO 8601 Timestamp

---

### 1.5 Team & Sub-IDs Tab
| # | API Endpoint | HTTP Method | Triggering UI Method | Line in `manage_account_screen.dart` | Repository & Service |
|---|---|---|---|---|---|
| 21 | `/api/subid/list` | `GET` | `_loadSubIds()` | L1019–1035, L4284–4420 | `UserRepository.listSubIds()` |
| 22 | `/api/subid/create` | `POST` | `_openCreateSubIdDialog()` -> `_handleCreateSubId()` | L6185–6217 | `UserRepository.createSubId()` |
| 23 | `/api/subid/{id}` | `DELETE` | `_confirmDeleteSubId(id, username)` | L4524–4553 | `UserRepository.deleteSubId(id)` |
| 24 | `/api/users/{id}/approve` | `PATCH` | `_approveChildAccount(subId)` | L1037–1060 | `UserRepository.approveChildAccount(subId)` |

#### Details: Create Sub-ID Request Payload:
```json
{
  "prefix": "sales",
  "password": "TempPassword123!",
  "firstName": "John",
  "lastName": "Doe",
  "accountType": "BUSINESS",
  "permissions": [1, 2, 3]
}
```

---

### 1.6 Account Storage Tab
| # | API Endpoint | HTTP Method | Triggering UI Method | Line in `manage_account_screen.dart` | Repository & Service |
|---|---|---|---|---|---|
| 25 | `/api/mail/storage-quota` | `GET` | `_loadStorageQuota()` | L130–146, L4558–4670 | `StorageRepository.fetchStorageQuota()` |

#### Details:
- Displays usage bar, used MB/GB, maximum quota (e.g., 5 GB), status badge (`Normal`, `Warning`, `High`, `Critical`), and breakdowns.

---

### 1.7 B2Auth Tab & Signing in to BNX Subpage
| # | API Endpoint | HTTP Method | Triggering UI Method | Line in `manage_account_screen.dart` | Repository & Service |
|---|---|---|---|---|---|
| 26 | `/api/users/2fa/setup` | `POST` | `_open2FAManagement()` | L438–470 | `ref.read(settingsProvider.notifier).setup2FA()` -> `SettingsRepository.setup2FA()` |
| 27 | `/api/users/2fa/verify` | `POST` | `_show2FASetupDialog()` verify button | L660–705 | `ref.read(settingsProvider.notifier).verify2FA(code)` -> `SettingsRepository.verify2FA()` |
| 28 | `/api/users/2fa/disable` | `POST` | `_open2FAManagement()` disable action | L412–436 | `ref.read(settingsProvider.notifier).disable2FA()` -> `SettingsRepository.disable2FA()` |
| 29 | `/api/auth/change-password` | `POST` | `_openChangePasswordDialog()` | L210–384, L342 | `UserRepository.changePassword(oldP, newP)` |

#### Details:
- **2FA Setup**: Returns secret key and QR code data (`TwoFactorSetupData`).
- **2FA Verify**: Takes 6-digit TOTP code `{"code": "123456"}` and activates 2FA.
- **Change Password**: Takes `{"currentPassword": "...", "newPassword": "..."}`.

---

### 1.8 Sign Out
| # | API Endpoint | HTTP Method | Triggering UI Method | Line in `manage_account_screen.dart` | Repository & Service |
|---|---|---|---|---|---|
| 30 | `/api/auth/logout` | `POST` | `_handleSignOut()` | L5150–5200 | `ref.read(accountsProvider.notifier).signOutSingleAccount()` -> `AuthRepository.logoutSpecificAccount()` |

---

## 2. Directory Structure of Copied Bundle

```
manage_account_api_bundle/
├── API_INTEGRATION_GUIDE.md
├── PROMPT_FOR_OTHER_PROJECT.txt
├── core/
│   ├── network/
│   │   ├── api_client.dart
│   │   ├── api_exception.dart
│   │   └── token_service.dart
│   └── widgets/
│       └── avatar_widget.dart
├── data/
│   ├── providers/
│   │   ├── account_provider.dart
│   │   └── settings_provider.dart
│   └── repositories/
│       ├── auth_repository.dart
│       ├── settings_repository.dart
│       ├── storage_repository.dart
│       ├── subscription_repository.dart
│       └── user_repository.dart
├── models/
│   ├── account_model.dart
│   ├── blocked_contact_model.dart
│   ├── signature_model.dart
│   ├── two_factor_model.dart
│   ├── user_model.dart
│   └── user_settings_model.dart
└── reference_ui/
    └── manage_account_screen_reference.dart
```
