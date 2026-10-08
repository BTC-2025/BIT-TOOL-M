/// Base exception for API and network errors.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// 401 Unauthorized: token is invalid, expired, or rejected by server.
class UnauthorizedException extends ApiException {
  const UnauthorizedException([
    super.message = 'Authentication failed. Please sign in again.',
  ]) : super(statusCode: 401);
}

/// Invalid credentials provided during sign in.
class InvalidCredentialsException extends ApiException {
  const InvalidCredentialsException([
    super.message = 'Invalid Credentials',
  ]) : super(statusCode: 400);
}

/// 403 Forbidden: user does not have permission.
class ForbiddenException extends ApiException {
  const ForbiddenException([
    super.message = 'You do not have permission to access this resource.',
  ]) : super(statusCode: 403);
}

/// 404 Not Found: endpoint or user resource was not found.
class NotFoundException extends ApiException {
  const NotFoundException([
    super.message = 'The requested resource was not found.',
  ]) : super(statusCode: 404);
}

/// 500-504 Server Error: backend failure.
class ServerException extends ApiException {
  const ServerException([
    super.message = 'Unable to connect to Bit Tool services right now.',
    int? statusCode,
  ]) : super(statusCode: statusCode);
}

/// Network connectivity, DNS, or socket failure.
class NetworkException extends ApiException {
  const NetworkException([
    super.message = 'Unable to connect. Please check your internet connection.',
  ]);
}

/// Network request timed out.
class RequestTimeoutException extends ApiException {
  const RequestTimeoutException([
    super.message = 'Request timed out. Please try again.',
  ]);
}

/// Unexpected JSON format or missing payload in response.
class InvalidResponseException extends ApiException {
  const InvalidResponseException([
    super.message = 'Unexpected response received from the server.',
  ]);
}
