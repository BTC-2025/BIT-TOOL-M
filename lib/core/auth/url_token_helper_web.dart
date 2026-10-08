// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Web implementation for extracting and removing the SSO token from the URL.
String? extractAndClearUrlToken() {
  try {
    final currentUri = Uri.parse(html.window.location.href);
    String? token;

    // 1. Check primary query parameters: ?token=...
    if (currentUri.queryParameters.containsKey('token')) {
      token = currentUri.queryParameters['token'];
    }

    // 2. Check fragment query parameters: #/?token=... or #/route?token=...
    if ((token == null || token.isEmpty) && currentUri.fragment.isNotEmpty) {
      final fragment = currentUri.fragment;
      final qIndex = fragment.indexOf('?');
      if (qIndex != -1) {
        final fragQuery = fragment.substring(qIndex + 1);
        final fragParams = Uri.splitQueryString(fragQuery);
        if (fragParams.containsKey('token')) {
          token = fragParams['token'];
        }
      }
    }

    if (token == null || token.trim().isEmpty) {
      return null;
    }

    final sanitizedToken = token.trim();

    // 3. Remove 'token' parameter from the visible URL without triggering a page reload.
    final updatedQueryParams = Map<String, String>.from(
      currentUri.queryParameters,
    )..remove('token');

    String updatedFragment = currentUri.fragment;
    final qIndex = updatedFragment.indexOf('?');
    if (qIndex != -1) {
      final fragPath = updatedFragment.substring(0, qIndex);
      final fragQuery = updatedFragment.substring(qIndex + 1);
      final fragParams = Map<String, String>.from(
        Uri.splitQueryString(fragQuery),
      )..remove('token');

      if (fragParams.isEmpty) {
        updatedFragment = fragPath;
      } else {
        final newFragQuery = Uri(queryParameters: fragParams).query;
        updatedFragment = '$fragPath?$newFragQuery';
      }
    }

    final cleanUri = Uri(
      scheme: currentUri.scheme,
      userInfo: currentUri.userInfo,
      host: currentUri.host,
      port: currentUri.hasPort ? currentUri.port : null,
      path: currentUri.path,
      queryParameters: updatedQueryParams.isEmpty ? null : updatedQueryParams,
      fragment: updatedFragment.isEmpty ? null : updatedFragment,
    );

    html.window.history.replaceState(
      null,
      html.document.title,
      cleanUri.toString(),
    );

    return sanitizedToken;
  } catch (_) {
    return null;
  }
}
