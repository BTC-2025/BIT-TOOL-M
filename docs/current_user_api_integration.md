# Bit Tool — Current User API Integration

## 1. Overview
This document specifies the first API integration for Bit Tool: retrieving the currently authenticated user profile via `GET https://api.bnxmail.com/api/users/me`.

---

## 2. API Configuration
- **Base URL**: `https://api.bnxmail.com`
- **Current Endpoint**: `/api/users/me`
- **Full URI**: `https://api.bnxmail.com/api/users/me`
- **HTTP Method**: `GET`
- **Request Timeout**: 15 seconds
- **Centralized Config**: [`lib/core/api/api_config.dart`](file:///Users/btrldev004/Desktop/BIT-TOOL-M/lib/core/api/api_config.dart)

---

## 3. Authentication Mechanism
- **SSO URL Redirect**: When users redirect to Bit Tool, the SSO token is delivered via query parameter:
  `https://your-bit-tool-app.com/?token=BNX_AUTH_TOKEN`
- **Detection & Extraction**: [`lib/core/auth/url_token_helper.dart`](file:///Users/btrldev004/Desktop/BIT-TOOL-M/lib/core/auth/url_token_helper.dart) extracts the token on app startup.
- **URL Sanitization**: On web platforms, the token is stripped from the visible browser address bar via `window.history.replaceState` without reloading or resetting routes.
- **Headers Sent**:
  ```http
  Content-Type: application/json
  Accept: application/json
  Authorization: Bearer <bnx_auth_token>
  ```
- **Logging Security**:
  Authorization headers, Bearer tokens, and SSO credentials are strictly redacted (`[REDACTED]`) in all debug logs.

---

## 4. Token Storage
- **Storage Key**: `bnx_auth_token`
- **Abstraction**: [`lib/core/auth/auth_storage.dart`](file:///Users/btrldev004/Desktop/BIT-TOOL-M/lib/core/auth/auth_storage.dart)
  - **Flutter Web**: Stored directly in `window.localStorage['bnx_auth_token']`.
  - **Mobile/Desktop (macOS/iOS/Android/Windows/Linux)**: Stored in `SharedPreferences` with exact key `'bnx_auth_token'`.
- **API**:
  - `Future<void> saveToken(String token)`
  - `Future<String?> getToken()`
  - `Future<void> removeToken()`
  - `Future<bool> hasToken()`

---

## 5. User & Organization Models
Defined in [`lib/core/models/user_model.dart`](file:///Users/btrldev004/Desktop/BIT-TOOL-M/lib/core/models/user_model.dart):
- **`UserModel` Fields**:
  - `id` (int)
  - `email` (String)
  - `firstName` (String?)
  - `lastName` (String?)
  - `fullName` (String?)
  - `profilePictureUrl` (String?)
  - `role` (String?)
  - `accountType` (String?)
  - `storageUsed` (num?)
  - `storageLimit` (num?)
  - `isPrimary` (bool)
  - `phoneNumber` (String?)
  - `recoveryEmail` (String?)
  - `dob` (String?)
  - `organization` (`OrganizationModel`?)
- **`OrganizationModel` Fields**:
  - `id` (int)
  - `name` (String)
- **Safe Fallbacks**:
  - `displayName`: Prefers `fullName`, falls back to `firstName + lastName`, then email username, never "null" or empty.
  - `initials`: 1-2 character uppercase initials derived dynamically.
  - `hasValidProfilePicture`: Validates URL format before attempting network render.
  - All optional fields (`phoneNumber`, `recoveryEmail`, `dob`, `organization`, etc.) are parsed null-safely.

---

## 6. API Service & Client
- **`ApiClient`** ([`lib/core/api/api_client.dart`](file:///Users/btrldev004/Desktop/BIT-TOOL-M/lib/core/api/api_client.dart)):
  Handles request timeouts, sanitized debug logging, standard headers, and maps HTTP status codes to typed exceptions.
- **`UserApiService`** ([`lib/core/services/user_api_service.dart`](file:///Users/btrldev004/Desktop/BIT-TOOL-M/lib/core/services/user_api_service.dart)):
  Retrieves the stored token, executes `GET /api/users/me`, validates the JSON response envelope (`success: true`, `data != null`), and constructs `UserModel`.

---

## 7. Authentication State Management
- **`AuthProvider`** ([`lib/core/providers/auth_provider.dart`](file:///Users/btrldev004/Desktop/BIT-TOOL-M/lib/core/providers/auth_provider.dart)):
  - State Enum: `AuthStatus`
    - `unauthenticated`: No token stored.
    - `authenticating`: Loading state while fetching profile.
    - `authenticated`: User successfully loaded and available.
    - `tokenExpired`: 401 received; token cleared from storage.
    - `authenticationError`: Network, 5xx server, or timeout error with retry capability.
  - **Lifecycle on Startup**:
    1. Inspects URL for `?token=...`.
    2. Saves token to storage if present, and removes it from the URL.
    3. Checks persistent storage for `bnx_auth_token`.
    4. Calls `GET /api/users/me` if token is available.
    5. Deduplicates concurrent requests.
  - **Single Source of Truth**: Header pill, profile dropdown modal, and settings screen all consume this state.

---

## 8. Error Handling Matrix
| Scenario | Status Code / Exception | Action Taken | UI Behavior |
| :--- | :--- | :--- | :--- |
| **Invalid / Expired Token** | 401 `UnauthorizedException` | Token cleared from `AuthStorage`, user state reset, no infinite retries | Shows unauthenticated state |
| **Permission Denied** | 403 `ForbiddenException` | Token preserved | Permission error displayed |
| **Endpoint Missing** | 404 `NotFoundException` | Token preserved | Resource error displayed |
| **Server Error** | 500-504 `ServerException` | Token preserved | "Unable to connect to Bit Tool services right now." + Retry |
| **No Network / DNS** | `NetworkException` | Token preserved | "Unable to connect. Please check your internet connection." + Retry |
| **Timeout** | `RequestTimeoutException` | Request aborted | "Request timed out. Please try again." + Retry |
| **Malformed JSON** | `InvalidResponseException` | Caught safely without crash | Error displayed + Retry |

---

## 9. Verification & Testing
Run the comprehensive test suite:
```bash
flutter test
```
### Covered Tests:
- **TEST 1**: Valid token -> 200 -> user parsed -> authenticated state
- **TEST 2**: No token -> no API request -> unauthenticated state
- **TEST 3**: Invalid token (401) -> clears storage -> resets user -> no retry loop
- **TEST 4 & 10**: Token persistence across restarts and page refresh
- **TEST 5**: Profile image valid URL -> renders image
- **TEST 6**: Profile image null -> renders dynamic initials fallback
- **TEST 7**: Null optional fields -> no crash, no "null" text
- **TEST 8**: Network failure -> friendly error message + retry works
- **TEST 9**: 500 Server error -> friendly message + retry works
- **Sanitized Logging**: Authorization header is redacted in logs
