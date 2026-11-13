# Bit Tool API Module

A standalone, modular Dart/Flutter package containing all the API services, data models, client, and registry for **Bit Tool** features.

Designed specifically to be connected and embedded into a host application (such as **Cliks Business**) where Bit Tool is a side feature.

---

## Key Features

- **Decoupled Authentication:** Zero login APIs. Uses the host app's existing authentication token via a dynamic `tokenProvider` or static token.
- **Complete Feature Coverage:** Includes all module APIs:
  - **Contacts API** (`/get`, `/get-all`, `/get/:id`, `/add`, `/update/:id`, `/delete/:id`)
  - **Notes API** (`/`, `/:id`, `/create`, `/update/:id`, `/delete/:id`)
  - **Calendar API** (Categories, Events, Reminders, Date-linked Notes, Search)
  - **Calculator API** (Standard Tape history & sessions, Compare mode history & sessions)
  - **Notifications API** (`/notifications`, `/notifications/:id/read`, `/notifications/read-all`)
  - **Weather & Reverse Geocoding** (Open-Meteo, BigDataCloud)
  - **Currency Rates** (Frankfurter live conversion)
  - **User Profile Context** (`/users/me` read-only)
- **Programmatic Registry:** `BitToolApiRegistry` lists and searches all 35+ endpoints in code.
- **Interactive UI Directory Widget:** `BitToolApiDirectoryView` provides an embeddable visual explorer of all APIs with search, method badges, and schemas.
- **Zero Impact on Existing Project:** Completely self-contained in this folder.

---

## File Structure

```
bit_tool_api_module/
├── pubspec.yaml                 # Standalone package definition
├── README.md                    # Getting started & overview
├── API_DOCUMENTATION.md         # Full API integration & schemas documentation
├── API_QUICK_REFERENCE.md       # Quick lookup cheat sheet
├── endpoints_catalog.json       # Complete machine-readable JSON catalog
├── test/
│   └── bit_tool_api_module_test.dart
└── lib/
    ├── bit_tool_api_module.dart # Main library export
    └── src/
        ├── config/              # Base URLs, paths, and endpoint descriptor
        ├── client/              # HTTP Client & typed exceptions
        ├── registry/            # Central catalog listing all endpoints
        ├── facade/              # Unified BitToolApiModule facade
        ├── ui/                  # Embeddable BitToolApiDirectoryView
        └── modules/
            ├── contacts/
            ├── notes/
            ├── calendar/
            ├── calculator/
            ├── notifications/
            ├── weather/
            ├── currency/
            └── user_profile/
```

---

## Usage in Host App (e.g. Cliks Business)

```dart
import 'package:bit_tool_api_module/bit_tool_api_module.dart';

// 1. Initialize
final bitTool = BitToolApiModule(
  tokenProvider: () async => hostAppAuthService.getAccessToken(),
);

// 2. Call module APIs
final contacts = await bitTool.contacts.getAllContacts();
final notes = await bitTool.notes.getNotes();
final monthEvents = await bitTool.calendar.getMonthEvents(year: 2026, month: 11);
final tapeHistory = await bitTool.calculator.getHistory();
final notifications = await bitTool.notifications.getNotifications();

// 3. Or embed the visual API Directory widget in your UI
Widget buildBitToolPanel() {
  return const BitToolApiDirectoryView();
}
```

