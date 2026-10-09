import '../api/api_client.dart';
import '../api/api_config.dart';
import '../api/api_exceptions.dart';
import '../auth/auth_storage.dart';
import '../models/user_model.dart';

/// Dedicated service responsible for user-related API interactions.
class UserApiService {
  final ApiClient _apiClient;
  final AuthStorage _authStorage;

  UserApiService({ApiClient? apiClient, AuthStorage? authStorage})
    : _apiClient = apiClient ?? ApiClient(),
      _authStorage = authStorage ?? AuthStorage();

  /// Retrieves the currently authenticated user's profile from GET /api/users/me.
  ///
  /// Throws [UnauthorizedException] if no token is saved or if token is rejected.
  /// Throws [InvalidResponseException] if the response structure is malformed.
  Future<UserModel> getCurrentUser() async {
    final token = await _authStorage.getToken();
    if (token == null || token.trim().isEmpty) {
      throw const UnauthorizedException('No authentication token available.');
    }

    final dynamic rawResponse = await _apiClient.get(
      ApiConfig.currentUserUri,
      token: token,
    );

    if (rawResponse is! Map<String, dynamic>) {
      throw const InvalidResponseException(
        'Server response is not a valid JSON object.',
      );
    }

    final success = rawResponse['success'] == true;
    final message =
        rawResponse['message']?.toString() ?? 'Failed to retrieve profile.';

    if (!success) {
      throw ApiException(message);
    }

    final data = rawResponse['data'];
    if (data == null || data is! Map<String, dynamic>) {
      throw const InvalidResponseException(
        'User profile data is missing from server response.',
      );
    }

    try {
      return UserModel.fromJson(data);
    } catch (e) {
      throw InvalidResponseException(
        'Failed to parse user profile: ${e.toString()}',
      );
    }
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final dynamic rawResponse = await _apiClient.post(
      ApiConfig.loginUri,
      body: {'email': email.trim(), 'password': password},
    );

    if (rawResponse is! Map<String, dynamic>) {
      throw const InvalidResponseException(
        'Server response is not a valid JSON object.',
      );
    }

    final success = rawResponse['success'] == true;
    final message = rawResponse['message']?.toString() ?? 'Login failed.';

    if (!success) {
      if (message.toLowerCase().contains('credential') ||
          message.toLowerCase().contains('invalid')) {
        throw const InvalidCredentialsException('Invalid Credentials');
      }
      throw ApiException(message);
    }

    final data = rawResponse['data'];
    String? token;
    if (data is Map<String, dynamic>) {
      token =
          data['token']?.toString() ??
          data['accessToken']?.toString() ??
          data['jwt']?.toString();
    } else if (data is String) {
      token = data;
    }

    if (token == null || token.trim().isEmpty) {
      throw const InvalidResponseException(
        'Authentication token missing from login response.',
      );
    }

    await _authStorage.saveToken(token.trim());

    return getCurrentUser();
  }
}
