import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:bulk_tempo/features/auth/domain/models/user_entity.dart';

part 'auth_state.freezed.dart';

@freezed
abstract class AuthState with _$AuthState {
  const AuthState._();

  const factory AuthState({
    UserEntity? user,
    @Default(true) bool isInitializing,
    String? errorMessage,
  }) = _AuthState;

  bool get isAuthenticated => user != null;
}
