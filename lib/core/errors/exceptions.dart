abstract class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

class ServerException extends AppException {
  final int? statusCode;

  const ServerException({
    String message = 'Server error occurred',
    this.statusCode,
  }) : super(message);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServerException &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          statusCode == other.statusCode;

  @override
  int get hashCode => message.hashCode ^ statusCode.hashCode;

  @override
  String toString() =>
      'ServerException(message: $message, statusCode: $statusCode)';
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'Network connection error']);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NetworkException &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}

class AuthException extends AppException {
  final String code;

  const AuthException(this.code, String message) : super(message);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthException &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          message == other.message;

  @override
  int get hashCode => code.hashCode ^ message.hashCode;

  @override
  String toString() => 'AuthException(code: $code, message: $message)';
}

class CacheException extends AppException {
  const CacheException([super.message = 'Cache error occurred']);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CacheException &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}
