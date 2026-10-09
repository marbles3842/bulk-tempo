import 'dart:async';

import 'package:bulk_tempo/core/errors/failures.dart';
import 'package:bulk_tempo/core/result/result.dart';
import 'package:bulk_tempo/features/auth/domain/models/user_entity.dart';
import 'package:bulk_tempo/features/auth/domain/repositories/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  final StreamController<UserEntity?> _authStateController =
      StreamController<UserEntity?>.broadcast();

  final Map<String, UserEntity> _users = {};
  final Map<String, String> _passwords = {};

  UserEntity? _currentUser;

  AppFailure? nextFailure;
  AppFailure? signInFailure;
  AppFailure? signUpFailure;
  AppFailure? signOutFailure;

  FakeAuthRepository({UserEntity? initialUser}) {
    if (initialUser != null) {
      _currentUser = initialUser;
      _users[initialUser.email] = initialUser;
      _passwords[initialUser.email] = 'password';
    }
  }

  @override
  Stream<UserEntity?> authStateChanges() async* {
    yield _currentUser;
    yield* _authStateController.stream;
  }

  @override
  UserEntity? get currentUser => _currentUser;

  @override
  Future<Result<UserEntity, AppFailure>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final failure = nextFailure ?? signInFailure;
    if (failure != null) {
      nextFailure = null;
      return Result.failure(failure);
    }

    final user = _users[email];
    if (user == null || _passwords[email] != password) {
      return const Result.failure(AuthFailure('Invalid email or password'));
    }

    _currentUser = user;
    _authStateController.add(user);
    return Result.success(user);
  }

  @override
  Future<Result<UserEntity, AppFailure>> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final failure = nextFailure ?? signUpFailure;
    if (failure != null) {
      nextFailure = null;
      return Result.failure(failure);
    }

    if (_users.containsKey(email)) {
      return const Result.failure(
        AuthFailure('An account with this email already exists'),
      );
    }

    final user = UserEntity(id: 'user_${_users.length + 1}', email: email);

    _users[email] = user;
    _passwords[email] = password;
    _currentUser = user;
    _authStateController.add(user);

    return Result.success(user);
  }

  @override
  Future<Result<void, AppFailure>> signOut() async {
    final failure = nextFailure ?? signOutFailure;
    if (failure != null) {
      nextFailure = null;
      return Result.failure(failure);
    }

    _currentUser = null;
    _authStateController.add(null);
    return const Result.success(null);
  }

  void setCurrentUser(UserEntity? user) {
    _currentUser = user;
    if (user != null) {
      _users[user.email] = user;
    }
    _authStateController.add(user);
  }

  void seedUser({required UserEntity user, required String password}) {
    _users[user.email] = user;
    _passwords[user.email] = password;
  }

  void reset() {
    _users.clear();
    _passwords.clear();
    _currentUser = null;
    nextFailure = null;
    signInFailure = null;
    signUpFailure = null;
    signOutFailure = null;
    _authStateController.add(null);
  }

  void dispose() {
    _authStateController.close();
  }
}
