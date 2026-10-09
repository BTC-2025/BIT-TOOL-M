class ApiConfig {
  ApiConfig._();

  /// Base URL for the Bit Tool APIs.
  /// Configurable via VITE_API_BASE_URL environment define with https://api.bnxmail.com as default.
  static const String _rawBaseUrl = String.fromEnvironment(
    'VITE_API_BASE_URL',
    defaultValue: 'https://api.bnxmail.com',
  );

  /// Normalized base URL without trailing slash.
  static String get baseUrl {
    var url = _rawBaseUrl.trim();
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  /// Normalizes an endpoint with baseUrl, ensuring `/api` prefix consistency without duplicates.
  static Uri buildUri(String endpoint) {
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    if (baseUrl.endsWith('/api') && cleanEndpoint.startsWith('/api/')) {
      return Uri.parse('$baseUrl${cleanEndpoint.substring(4)}');
    }
    return Uri.parse('$baseUrl$cleanEndpoint');
  }

  /// Endpoint to authenticate user with credentials.
  static const String loginEndpoint = '/api/auth/login';

  /// Endpoint to fetch current authenticated user profile.
  static const String currentUserEndpoint = '/api/users/me';

  /// Full URI for the login endpoint.
  static Uri get loginUri => buildUri(loginEndpoint);

  /// Full URI for the current user endpoint.
  static Uri get currentUserUri => buildUri(currentUserEndpoint);

  /// Notifications endpoints
  static const String notificationsEndpoint = '/api/notifications';
  static String notificationReadEndpoint(String id) =>
      '/api/notifications/$id/read';
  static const String notificationsReadAllEndpoint =
      '/api/notifications/read-all';

  /// Full URI for the notifications endpoint.
  static Uri get notificationsUri => buildUri(notificationsEndpoint);

  /// Full URI for marking a single notification as read.
  static Uri notificationReadUri(String id) =>
      buildUri(notificationReadEndpoint(id));

  /// Full URI for marking all notifications as read.
  static Uri get notificationsReadAllUri =>
      buildUri(notificationsReadAllEndpoint);

  /// Base URL for the Contacts API.
  /// Configurable via VITE_CONTACT_API_BASE_URL environment define with https://api.bit-tool.com/api/contacts as default.
  static const String _rawContactBaseUrl = String.fromEnvironment(
    'VITE_CONTACT_API_BASE_URL',
    defaultValue: 'https://api.bit-tool.com/api/contacts',
  );

  /// Normalized contacts base URL without trailing slash.
  static String get contactBaseUrl {
    var url = _rawContactBaseUrl.trim();
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  /// Builds a URI targeting the Contacts service.
  static Uri buildContactUri(
    String endpoint, [
    Map<String, dynamic>? queryParameters,
  ]) {
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final baseUri = Uri.parse('$contactBaseUrl$cleanEndpoint');
    if (queryParameters != null && queryParameters.isNotEmpty) {
      final sanitizedParams = <String, String>{};
      queryParameters.forEach((key, value) {
        if (value != null) {
          sanitizedParams[key] = value.toString();
        }
      });
      return baseUri.replace(queryParameters: sanitizedParams);
    }
    return baseUri;
  }

  /// Contacts endpoints
  static const String contactsGetEndpoint = '/get';
  static const String contactsGetAllEndpoint = '/get-all';
  static String contactGetByIdEndpoint(String id) => '/get/$id';
  static const String contactAddEndpoint = '/add';
  static String contactUpdateEndpoint(String id) => '/update/$id';
  static String contactDeleteEndpoint(String id) => '/delete/$id';

  /// Contacts URIs
  static Uri contactsGetUri([Map<String, dynamic>? queryParameters]) =>
      buildContactUri(contactsGetEndpoint, queryParameters);
  static Uri contactsGetAllUri([Map<String, dynamic>? queryParameters]) =>
      buildContactUri(contactsGetAllEndpoint, queryParameters);
  static Uri contactGetByIdUri(String id) =>
      buildContactUri(contactGetByIdEndpoint(id));
  static Uri get contactAddUri => buildContactUri(contactAddEndpoint);
  static Uri contactUpdateUri(String id) =>
      buildContactUri(contactUpdateEndpoint(id));
  static Uri contactDeleteUri(String id) =>
      buildContactUri(contactDeleteEndpoint(id));

  /// Standard request timeout.
  static const Duration requestTimeout = Duration(seconds: 15);
}
