# Bit Tool Module API Integration & Specification

This documentation provides the technical specification for embedding Bit Tool feature APIs into a host application (such as **Cliks Business** or another Flutter/Web/Mobile system).

---

## 1. Architectural Philosophy: Side-Feature Integration

When Bit Tool functions as a side feature inside a host application:
1. **Authentication is Decoupled:** The host application already manages user login, sessions, and tokens.
2. **Zero Login APIs:** Endpoints like `/api/auth/login` are strictly excluded. The host app provides its existing `bnx_auth_token` or SSO session token.
3. **No Storage Collisions:** The module does not attempt to read or write local storage keys, avoiding conflicts with the host app's storage.
4. **Customizable Base URLs:** All base URLs have cloud defaults but can be overridden per environment (staging, production, local).

```
+-----------------------------------------------------------+
| Host Application (e.g. Cliks Business)                    |
| - Manages User Login, Session, and Storage                |
| - Owns Bearer Auth Token                                  |
+-----------------------------+-----------------------------+
                              | passes tokenProvider / token
                              v
+-----------------------------------------------------------+
| BitToolApiModule (Standalone Package)                     |
|                                                           |
|  +--------------------+  +--------------------+           |
|  | Contacts API       |  | Notes API          |           |
|  +--------------------+  +--------------------+           |
|  | Calendar API       |  | Calculator API     |           |
|  +--------------------+  +--------------------+           |
|  | Notifications API  |  | Weather & Currency |           |
|  +--------------------+  +--------------------+           |
|  | User Profile API   |  | API Directory View |           |
|  +--------------------+  +--------------------+           |
+-----------------------------------------------------------+
```

---

## 2. Quick Integration Guide

### Step 1: Add Dependency or Copy Module
In your host application's `pubspec.yaml`:
```yaml
dependencies:
  bit_tool_api_module:
    path: ../bit_tool_api_module
```
Or simply copy the `bit_tool_api_module` directory into your project.

### Step 2: Initialize with Host App Token
```dart
import 'package:bit_tool_api_module/bit_tool_api_module.dart';

// Initialize with a dynamic token provider callback from your auth service
final bitTool = BitToolApiModule(
  tokenProvider: () async {
    return await myAuthService.getAccessToken();
  },
);
```

### Step 3: Call Any Module API
```dart
// Fetch contacts
final contacts = await bitTool.contacts.getAllContacts();

// Fetch notes
final notes = await bitTool.notes.getNotes(allApps: true);

// Fetch calendar events
final events = await bitTool.calendar.getMonthEvents(year: 2026, month: 11);

// Add calculation to calculator history
final session = await bitTool.calculator.createSession(
  title: 'Invoice Disbursal',
  applicationName: 'Cliks Business',
);

// Fetch notifications
final notifications = await bitTool.notifications.getNotifications();
```

---

## 3. Module Specifications & Endpoints

### 3.1 Contacts Module
* **Base URL:** `https://api.bit-tool.com/api/contacts`
* **Service Class:** `ContactsApiService`

#### Endpoints:
1. **`GET /get`**: Paginated contacts.
   * Query params: `page` (int), `limit` (int), `search` (string).
   * Response: `{ data: [Contact], count: int, page: int, limit: int }`

2. **`GET /get-all`**: All contacts with automatic pagination & deduplication across apps.
   * Query params: `offset` (int), `limit` (int).
   * Response: Array of contacts.

3. **`GET /get/:id`**: Single contact profile by ID.

4. **`POST /add`**: Create contact.
   * Body:
     ```json
     {
       "firstName": "Sarah",
       "lastName": "Jenkins",
       "email": "sarah@cliks.com",
       "phone": "+91 9876543210",
       "company": "Cliks Business",
       "role": "Finance Lead",
       "notes": "Office contact"
     }
     ```

5. **`PUT /update/:id`**: Update contact.
   * Body: Partial fields to update.

6. **`DELETE /delete/:id`**: Delete contact by ID.

---

### 3.2 Notes Module
* **Base URL:** `https://api.bit-tool.com/api/notes`
* **Service Class:** `NotesApiService`

#### Endpoints:
1. **`GET /`**: Fetch notes list.
   * Query params: `allApps=true` (fetches notes across all integrated apps).
   * Response: `{ data: [NoteModel] }`

2. **`GET /:id`**: Fetch note by ID.

3. **`POST /create`**: Create note.
   * Body:
     ```json
     {
       "title": "Commercial Office Rent",
       "content": "Due on 1st of every month",
       "color": "#A7F3D0",
       "isPinned": true,
       "applicationName": "Cliks Business"
     }
     ```

4. **`PUT /update/:id`**: Update note.
   * Body:
     ```json
     {
       "title": "Updated Title",
       "content": "Updated content",
       "isPinned": false,
       "isArchived": false
     }
     ```

5. **`DELETE /delete/:id`**: Delete note by ID.

---

### 3.3 Calendar Module
* **Base URL:** `https://api.bit-tool.com/api/calendar`
* **Service Class:** `CalendarApiService`

#### Endpoints:
1. **`GET /categories`**: List all categories.
2. **`POST /categories`**: Create category (`{ "name": "Audit", "color": "#EF4444" }`).
3. **`GET /events/month?year=YYYY&month=MM`**: Month events list.
4. **`POST /events`**: Create event.
   * Body:
     ```json
     {
       "title": "Office Rent Payment",
       "startTime": "2026-11-01T10:00:00.000Z",
       "endTime": "2026-11-01T11:00:00.000Z",
       "categoryId": "cat_1",
       "description": "Monthly rent Rs 45,000"
     }
     ```
5. **`PUT /events/:id`**: Update event.
6. **`DELETE /events/:id`**: Delete event.
7. **`GET /reminders?date=YYYY-MM-DD`**: Get reminders for date.
8. **`POST /reminders`**: Create reminder (`{ "title": "Pay Bill", "date": "2026-11-10", "time": "14:00" }`).
9. **`PUT /reminders/:id`**: Update reminder.
10. **`PUT /reminders/:id/complete`**: Mark reminder completed.
11. **`DELETE /reminders/:id`**: Delete reminder.
12. **`GET /notes?date=YYYY-MM-DD`**: Get date-linked notes.
13. **`POST /notes`**: Create date-linked note (`{ "title": "Memo", "date": "2026-11-10", "content": "Text" }`).
14. **`PUT /notes/:id`**: Update date-linked note.
15. **`DELETE /notes/:id`**: Delete date-linked note.
16. **`GET /search?query={term}`**: Global search across events, reminders, and date notes.

---

### 3.4 Calculator Module
* **Base URL:** `https://api.bit-tool.com/api/calculator`
* **Service Class:** `CalculatorApiService`

#### Endpoints:
1. **`GET /history`**: Get standard tape history sessions.
2. **`GET /history/all`**: Get cross-app calculation history.
3. **`GET /sessions/:id`**: Get session with full tape item list.
4. **`POST /sessions`**: Create session (`{ "title": "Expenses", "mode": "business", "currency": "INR" }`).
5. **`POST /sessions/:sessionId/items`**: Add tape operation.
   * Body:
     ```json
     {
       "sequence": 1,
       "value": 45000,
       "operator": "+",
       "runningTotal": 45000,
       "label": "Rent"
     }
     ```
6. **`DELETE /sessions/:id`**: Delete session.
7. **`DELETE /sessions`**: Clear all standard sessions.
8. **`GET /compare/history`**: Get compare mode history.
9. **`POST /compare/sessions`**: Create compare session.
10. **`POST /compare/sessions/:sessionId/items`**: Add comparison row (Side A vs Side B).
11. **`PUT /compare/sessions/:sessionId/items/:itemId`**: Update comparison row.
12. **`DELETE /compare/sessions/:sessionId/items/:itemId`**: Delete comparison row.
13. **`DELETE /compare/sessions/:id`**: Delete compare session.
14. **`DELETE /compare/history`**: Clear compare history.

---

### 3.5 Notifications Module
* **Base URL:** `https://api.bit-tool.com/api`
* **Service Class:** `NotificationsApiService`

#### Endpoints:
1. **`GET /notifications`**: Get all notifications for user.
2. **`PUT /notifications/:id/read`**: Mark single notification as read.
3. **`PUT /notifications/read-all`**: Mark all notifications as read.

---

### 3.6 Weather & Geocoding Module (Public Third-Party)
* **Service Class:** `WeatherApiService`
* **Endpoints:**
  1. `GET https://api.open-meteo.com/v1/forecast`: Current weather and daily/hourly forecasts.
  2. `GET https://api.bigdatacloud.net/data/reverse-geocode-client`: Resolves GPS coordinates into City and Country.

---

### 3.7 Currency Converter Module (Public Third-Party)
* **Service Class:** `CurrencyRateService`
* **Endpoints:**
  1. `GET https://api.frankfurter.dev/v2/currencies`: Supported currency dictionary.
  2. `GET https://api.frankfurter.dev/v2/rates?base=USD&quotes=INR`: Live exchange rates.

---

### 3.8 User Profile Context Module
* **Base URL:** `https://api.bnxmail.com/api`
* **Service Class:** `UserProfileApiService`
* **Endpoint:**
  * **`GET /users/me`**: Fetches current user profile, organization info, and role.
  * **Authentication:** Uses the host app's bearer token.
  * **Login Endpoint Status:** Excluded.

