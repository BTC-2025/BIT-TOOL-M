library bit_tool_api_module;

// Central Module Facade
export 'src/facade/bit_tool_api_facade.dart';

// Configuration and Registry
export 'src/config/api_config.dart';
export 'src/config/endpoint_descriptor.dart';
export 'src/registry/bit_tool_api_registry.dart';

// Client and Exceptions
export 'src/client/api_client.dart';
export 'src/client/api_exceptions.dart';

// Feature Modules: Contacts
export 'src/modules/contacts/contacts_api_service.dart';
export 'src/modules/contacts/contact_model.dart';

// Feature Modules: Notes
export 'src/modules/notes/notes_api_service.dart';
export 'src/modules/notes/note_model.dart';

// Feature Modules: Calendar
export 'src/modules/calendar/calendar_api_service.dart';
export 'src/modules/calendar/calendar_models.dart';

// Feature Modules: Calculator
export 'src/modules/calculator/calculator_api_service.dart';
export 'src/modules/calculator/calculator_models.dart';

// Feature Modules: Notifications
export 'src/modules/notifications/notifications_api_service.dart';
export 'src/modules/notifications/notification_model.dart';

// Feature Modules: Weather & Geocoding
export 'src/modules/weather/weather_api_service.dart';
export 'src/modules/weather/weather_model.dart';

// Feature Modules: Currency Rates
export 'src/modules/currency/currency_rate_service.dart';
export 'src/modules/currency/currency_models.dart';

// Feature Modules: User Profile Context (NO LOGIN)
export 'src/modules/user_profile/user_profile_api_service.dart';
export 'src/modules/user_profile/user_profile_model.dart';

// UI Directory View Component
export 'src/ui/bit_tool_api_directory_view.dart';

