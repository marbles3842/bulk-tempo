import 'package:bulk_tempo/features/auth/domain/models/user_entity.dart';

const Object _sentinel = Object();

class AuthState {
  final UserEntity? user;
  final bool isInitializing;
  final String? errorMessage;

  const AuthState({this.user, this.isInitializing = true, this.errorMessage});

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    Object? user = _sentinel,
    bool? isInitializing,
    Object? errorMessage = _sentinel,
  }) {
    return AuthState(
      user: identical(user, _sentinel) ? this.user : user as UserEntity?,
      isInitializing: isInitializing ?? this.isInitializing,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthState &&
          runtimeType == other.runtimeType &&
          user == other.user &&
          isInitializing == other.isInitializing &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => Object.hash(user, isInitializing, errorMessage);

  @override
  String toString() =>
      'AuthState(user: $user, isInitializing: $isInitializing, errorMessage: $errorMessage)';
}
