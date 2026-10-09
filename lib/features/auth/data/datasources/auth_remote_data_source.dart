import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bulk_tempo/core/errors/exceptions.dart';
import 'package:bulk_tempo/features/auth/data/models/user_dto.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  return AuthRemoteDataSourceImpl(firebaseAuth);
});

abstract class AuthRemoteDataSource {
  Stream<UserDto?> authStateChanges();
  UserDto? get currentUser;
  Future<UserDto> signInWithEmailAndPassword({
    required String email,
    required String password,
  });
  Future<UserDto> signUpWithEmailAndPassword({
    required String email,
    required String password,
  });
  Future<void> signOut();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _firebaseAuth;

  AuthRemoteDataSourceImpl(this._firebaseAuth);

  @override
  Stream<UserDto?> authStateChanges() {
    return _firebaseAuth.authStateChanges().map(
      (user) => user != null ? UserDto.fromFirebaseUser(user) : null,
    );
  }

  @override
  UserDto? get currentUser {
    final user = _firebaseAuth.currentUser;
    return user != null ? UserDto.fromFirebaseUser(user) : null;
  }

  @override
  Future<UserDto> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthException('user-not-found', 'User not found');
      }
      return UserDto.fromFirebaseUser(user);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'network-request-failed') {
        throw NetworkException(e.message ?? 'Network error occurred');
      }
      throw AuthException(e.code, e.message ?? 'Authentication error');
    } on AppException {
      rethrow;
    } catch (e) {
      if (e.runtimeType.toString() == 'SocketException' ||
          e.toString().toLowerCase().contains('socketexception') ||
          e.toString().toLowerCase().contains('network')) {
        throw NetworkException(e.toString());
      }
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<UserDto> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthException('unknown', 'User creation failed');
      }
      return UserDto.fromFirebaseUser(user);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'network-request-failed') {
        throw NetworkException(e.message ?? 'Network error occurred');
      }
      throw AuthException(e.code, e.message ?? 'Authentication error');
    } on AppException {
      rethrow;
    } catch (e) {
      if (e.runtimeType.toString() == 'SocketException' ||
          e.toString().toLowerCase().contains('socketexception') ||
          e.toString().toLowerCase().contains('network')) {
        throw NetworkException(e.toString());
      }
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'network-request-failed') {
        throw NetworkException(e.message ?? 'Network error occurred');
      }
      throw AuthException(e.code, e.message ?? 'Sign out failed');
    } on AppException {
      rethrow;
    } catch (e) {
      if (e.runtimeType.toString() == 'SocketException' ||
          e.toString().toLowerCase().contains('socketexception') ||
          e.toString().toLowerCase().contains('network')) {
        throw NetworkException(e.toString());
      }
      throw ServerException(message: e.toString());
    }
  }
}
