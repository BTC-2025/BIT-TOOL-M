# BNX Storage & Quota Management API Documentation

This document describes all backend API endpoints integrated into the **BNX Storage & Quota Suite**.

---

## 🌐 Network Configuration & Authentication

- **Default Base URL**: `https://api.bnxmail.com` (Configurable at runtime via `ApiClient.setBaseUrl('https://api.yourdomain.com')`)
- **Authentication**: JWT Bearer token passed in the `Authorization` header:
  ```http
  Authorization: Bearer <access_token>
  ```
- **Content Type**: `application/json` (or `multipart/form-data` for file uploads)
- **Timeouts**: 20 seconds standard, 90 seconds for multipart vault uploads.

---

## 1. Storage Quota API

### `GET /api/mail/storage-quota`

Fetches real-time storage quota and usage breakdown for the authenticated user account.

#### Request Headers
```http
GET /api/mail/storage-quota HTTP/1.1
Host: api.bnxmail.com
Authorization: Bearer <access_token>
Accept: application/json
```

#### Response (200 OK)
```json
{
  "success": true,
  "message": "Storage quota retrieved successfully",
  "data": {
    "email": "ravinew2004@bnxmail.com",
    "storageLimit": 5368709120,
    "storageUsed": 10276044,
    "storagePercentage": 0.1914
  }
}
```

#### Field Specifications
| Field | Type | Description |
|---|---|---|
| `email` | `String` | Account email address associated with the quota |
| `storageLimit` | `int` | Maximum allocated quota in bytes (e.g. 5,368,709,120 = 5.00 GB) |
| `storageUsed` | `int` | Current used storage across mailbox in bytes (e.g. 10,276,044 = 9.80 MB) |
| `storagePercentage` | `double` | Percentage of quota consumed (0.0 to 100.0) |

#### UI Binding Points
- **Top Ecosystem Hero Card**: Displays `0.01 GB of 5.00 GB Used` with progress percentage.
- **Application Storage Card (Bnx mail)**: `9.80 MB Used`, `4.99 GB Free`, `0.19% Used`.
- **Storage Distribution Donut Chart**: Proportional multi-segment gauge.
- **Storage by Category**: Dynamic categories (Documents: 25%, Images: 15%, Attachments: 50%, Videos: 0%, Others: 10%).
- **Storage Health**: Evaluates health state:
  - `< 70%`: `Normal` (Green `#10B981`) — "STORAGE HEALTHY. WITHIN ALLOCATED QUOTA."
  - `70% - 84.9%`: `Warning` (Amber `#F59E0B`) — "STORAGE USAGE ELEVATED. MONITOR CAPACITY."
  - `85% - 94.9%`: `High` (Orange `#EA580C`) — "STORAGE RUNNING LOW. CLEANUP RECOMMENDED."
  - `≥ 95%`: `Critical` (Red `#EF4444`) — "STORAGE CRITICALLY FULL. ACTION REQUIRED."
- **Sidebar Storage Card Widget**: Compact sidebar widget showing `9.80 MB of 5.00 GB used`.

---

## 2. Mail Backup & Data Vault APIs

### 2.1 `GET /api/vault`

Fetches list of all backup archives, exported files, and mailbox backups stored in the user's persistent encrypted vault.

#### Request Headers
```http
GET /api/vault HTTP/1.1
Host: api.bnxmail.com
Authorization: Bearer <access_token>
Accept: application/json
```

#### Response (200 OK)
```json
{
  "success": true,
  "data": [
    {
      "id": 1042,
      "filename": "mailbox_backup_2026_q3.zip",
      "contentType": "application/zip",
      "size": 18454937,
      "createdAt": "2026-10-15T14:32:00.000Z"
    },
    {
      "id": 1043,
      "filename": "client_invoices_export.csv",
      "contentType": "text/csv",
      "size": 2451000,
      "createdAt": "2026-10-20T09:12:30.000Z"
    }
  ]
}
```

---

### 2.2 `POST /api/vault/upload`

Uploads an archive file, backup, or exported data stream directly into the encrypted Vault.

#### Request Headers
```http
POST /api/vault/upload HTTP/1.1
Host: api.bnxmail.com
Authorization: Bearer <access_token>
Content-Type: multipart/form-data; boundary=----WebKitFormBoundary7MA4YWxkTrZu0gW
```

#### Form Data
- `file`: Binary file stream (e.g. `.zip`, `.csv`, `.pdf`, `.eml`, `.mbox`)

#### Response (201 Created / 200 OK)
```json
{
  "success": true,
  "message": "File uploaded to Vault successfully",
  "data": {
    "id": 1044,
    "filename": "q4_archive.zip",
    "contentType": "application/zip",
    "size": 12849102,
    "createdAt": "2026-11-19T03:50:00.000Z"
  }
}
```

---

### 2.3 `DELETE /api/vault/{id}`

Permanently removes a backup file from the user's vault.

#### Request Headers
```http
DELETE /api/vault/1044 HTTP/1.1
Host: api.bnxmail.com
Authorization: Bearer <access_token>
```

#### Response (200 OK)
```json
{
  "success": true,
  "message": "Vault file deleted successfully"
}
```

---

### 2.4 `GET /api/vault/{id}/download`

Streams raw backup binary bytes for local downloading or offline storage.

#### Request Headers
```http
GET /api/vault/1044/download HTTP/1.1
Host: api.bnxmail.com
Authorization: Bearer <access_token>
```

#### Response (200 OK)
Binary stream with `Content-Type: application/octet-stream`.

---

## 3. Recycle Bin Restoration & Permanent Deletion APIs

### 3.1 `POST /api/mail/restore/{id}`

Restores a deleted item from the Recycle Bin back to its active origin folder (e.g. Inbox).

#### Request Headers
```http
POST /api/mail/restore/127 HTTP/1.1
Host: api.bnxmail.com
Authorization: Bearer <access_token>
```

#### Fallback Endpoint
If `POST /api/mail/restore/{id}` is not enabled on server, automatically falls back to:
`POST /api/mail/unarchive/{id}`.

---

### 3.2 `DELETE /api/mail/permanent/{id}?folder=Trash`

Permanently purges an item from the system, reclaiming storage quota.

#### Request Headers
```http
DELETE /api/mail/permanent/127?folder=Trash HTTP/1.1
Host: api.bnxmail.com
Authorization: Bearer <access_token>
```

#### Response (200 OK)
```json
{
  "success": true,
  "message": "Item permanently deleted"
}
```

---

## 4. Error Handling Standard

All endpoints throw a typed `ApiException`:
```dart
try {
  final quota = await StorageRepository.fetchStorageQuota();
} on ApiException catch (e) {
  print('HTTP error: ${e.statusCode} — ${e.message}');
  if (e.isAuthError) {
    // 401 Unauthorized -> Refresh token or redirect to login
  }
}
```
