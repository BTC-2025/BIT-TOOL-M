class ApiConfig {
  ApiConfig._();

  /// Base URL for the Bit Tool APIs.
  static const String baseUrl = 'https://api.bnxmail.com';

  /// Endpoint to authenticate user with credentials.
  static const String loginEndpoint = '/api/auth/login';

  /// Endpoint to fetch current authenticated user profile.
  static const String currentUserEndpoint = '/api/users/me';

  /// Full URI for the login endpoint.
  static Uri get loginUri => Uri.parse('$baseUrl$loginEndpoint');

  /// Full URI for the current user endpoint.
  static Uri get currentUserUri => Uri.parse('$baseUrl$currentUserEndpoint');

  /// Standard request timeout.
  static const Duration requestTimeout = Duration(seconds: 15);
}
