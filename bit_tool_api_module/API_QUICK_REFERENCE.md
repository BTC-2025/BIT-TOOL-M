# Bit Tool Module API Quick Reference

This cheat sheet summarizes all 35+ module endpoints in Bit Tool.
**Login APIs are strictly excluded** because the host app (e.g. Cliks Business) handles authentication directly.

---

## Global Authentication Header

For all endpoints where `Auth Required = Yes`:
```http
Authorization: Bearer <HOST_APP_AUTH_TOKEN>
Content-Type: application/json
Accept: application/json
```

---

## 1. Contacts Module (`https://api.bit-tool.com/api/contacts`)

| Method | Endpoint | Description | Auth Required |
| :--- | :--- | :--- | :---: |
| `GET` | `/get` | Get paginated contacts (`page`, `limit`, `search`) | Yes |
| `GET` | `/get-all` | Get all contacts across integrated apps (`offset`, `limit`) | Yes |
| `GET` | `/get/:id` | Get single contact profile by ID | Yes |
| `POST` | `/add` | Create new contact (`firstName`, `lastName`, `email`, `phone`, `company`, `role`) | Yes |
| `PUT` | `/update/:id` | Update contact record fields | Yes |
| `DELETE` | `/delete/:id` | Delete contact record by ID | Yes |

---

## 2. Notes Module (`https://api.bit-tool.com/api/notes`)

| Method | Endpoint | Description | Auth Required |
| :--- | :--- | :--- | :---: |
| `GET` | `/` | Get notes (`allApps=true` for cross-app notes) | Yes |
| `GET` | `/:id` | Get note details by ID | Yes |
| `POST` | `/create` | Create note (`title`, `content`, `color`, `isPinned`, `applicationName`) | Yes |
| `PUT` | `/update/:id` | Update note title, content, color, pinned or archived status | Yes |
| `DELETE` | `/delete/:id` | Delete note by ID | Yes |

---

## 3. Calendar Module (`https://api.bit-tool.com/api/calendar`)

| Method | Endpoint | Description | Auth Required |
| :--- | :--- | :--- | :---: |
| `GET` | `/categories` | List event categories and assigned colors | Yes |
| `POST` | `/categories` | Create custom event category (`name`, `color`) | Yes |
| `GET` | `/events/month` | Get events for month (`year=YYYY`, `month=MM`) | Yes |
| `POST` | `/events` | Schedule new calendar event | Yes |
| `PUT` | `/events/:id` | Update calendar event schedule or description | Yes |
| `DELETE` | `/events/:id` | Delete calendar event | Yes |
| `GET` | `/reminders` | Get reminders by date (`date=YYYY-MM-DD`) | Yes |
| `POST` | `/reminders` | Create reminder (`title`, `date`, `time`, `description`) | Yes |
| `PUT` | `/reminders/:id` | Update reminder | Yes |
| `PUT` | `/reminders/:id/complete` | Mark reminder as completed | Yes |
| `DELETE` | `/reminders/:id` | Delete reminder | Yes |
| `GET` | `/notes` | Get date-linked notes (`date=YYYY-MM-DD`) | Yes |
| `POST` | `/notes` | Create date-linked note (`title`, `date`, `content`) | Yes |
| `PUT` | `/notes/:id` | Update date-linked note | Yes |
| `DELETE` | `/notes/:id` | Delete date-linked note | Yes |
| `GET` | `/search` | Global search across events, reminders, and date notes (`query=term`) | Yes |

---

## 4. Calculator Module (`https://api.bit-tool.com/api/calculator`)

| Method | Endpoint | Description | Auth Required |
| :--- | :--- | :--- | :---: |
| `GET` | `/history` | Get standard calculation tape sessions | Yes |
| `GET` | `/history/all` | Get cross-app calculation history across all apps | Yes |
| `GET` | `/sessions/:id` | Get session details and tape items | Yes |
| `POST` | `/sessions` | Create calculation session | Yes |
| `POST` | `/sessions/:sessionId/items` | Add tape operation step (`sequence`, `value`, `operator`, `runningTotal`) | Yes |
| `DELETE` | `/sessions/:id` | Delete session | Yes |
| `DELETE` | `/sessions` | Clear all standard sessions | Yes |
| `GET` | `/compare/history` | Get price comparison history | Yes |
| `POST` | `/compare/sessions` | Create price comparison session | Yes |
| `POST` | `/compare/sessions/:sessionId/items` | Add compare item (Side A vs Side B) | Yes |
| `PUT` | `/compare/sessions/:sessionId/items/:itemId` | Update compare item | Yes |
| `DELETE` | `/compare/sessions/:sessionId/items/:itemId` | Delete compare item | Yes |
| `DELETE` | `/compare/sessions/:id` | Delete compare session | Yes |
| `DELETE` | `/compare/history` | Clear all comparison history | Yes |

---

## 5. Notifications Module (`https://api.bit-tool.com/api`)

| Method | Endpoint | Description | Auth Required |
| :--- | :--- | :--- | :---: |
| `GET` | `/notifications` | Get user notifications | Yes |
| `PUT` | `/notifications/:id/read` | Mark single notification as read | Yes |
| `PUT` | `/notifications/read-all` | Mark all notifications as read | Yes |

---

## 6. Weather & Geocoding Module (Public / External)

| Method | Endpoint | Description | Auth Required |
| :--- | :--- | :--- | :---: |
| `GET` | `https://api.open-meteo.com/v1/forecast` | Current weather, hourly and daily forecasts | No |
| `GET` | `https://api.bigdatacloud.net/data/reverse-geocode-client` | Reverse geocode coordinates to City & Country | No |

---

## 7. Currency Converter Module (Public / External)

| Method | Endpoint | Description | Auth Required |
| :--- | :--- | :--- | :---: |
| `GET` | `https://api.frankfurter.dev/v2/currencies` | List supported global currencies | No |
| `GET` | `https://api.frankfurter.dev/v2/rates` | Real-time exchange rate between currencies | No |

---

## 8. User Profile Context Module (`https://api.bnxmail.com/api`)

| Method | Endpoint | Description | Auth Required |
| :--- | :--- | :--- | :---: |
| `GET` | `/users/me` | Fetch authenticated user details & organization. **(Login API excluded)** | Yes |

