sealed class AppFailure {
  final String message;
  final int? statusCode;

  const AppFailure(this.message, {this.statusCode});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppFailure &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          statusCode == other.statusCode;

  @override
  int get hashCode => message.hashCode ^ statusCode.hashCode;

  @override
  String toString() =>
      '$runtimeType(message: $message, statusCode: $statusCode)';
}

class ServerFailure extends AppFailure {
  const ServerFailure(super.message, {super.statusCode});
}

class NetworkFailure extends AppFailure {
  const NetworkFailure(super.message);
}

class AuthFailure extends AppFailure {
  const AuthFailure(super.message, {super.statusCode});
}

class CacheFailure extends AppFailure {
  const CacheFailure(super.message);
}

class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message);
}

class UnknownFailure extends AppFailure {
  const UnknownFailure(super.message);
}
