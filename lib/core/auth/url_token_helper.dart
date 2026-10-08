import 'url_token_helper_io.dart'
    if (dart.library.html) 'url_token_helper_web.dart';

/// Helper to safely inspect the current URL for an incoming SSO `?token=` parameter.
class UrlTokenHelper {
  UrlTokenHelper._();

  /// Extracts the SSO token from the URL if present, and removes it from the browser address bar.
  static String? extractAndClearToken() {
    return extractAndClearUrlToken();
  }
}
