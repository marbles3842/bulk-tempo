import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bulk_tempo/core/errors/exceptions.dart';
import 'package:bulk_tempo/core/errors/failures.dart';
import 'package:bulk_tempo/core/result/result.dart';
import 'package:bulk_tempo/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:bulk_tempo/features/auth/domain/models/user_entity.dart';
import 'package:bulk_tempo/features/auth/domain/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  return AuthRepositoryImpl(remoteDataSource);
});

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl(this._remoteDataSource);

  @override
  Stream<UserEntity?> authStateChanges() {
    return _remoteDataSource.authStateChanges().map(
      (userDto) => userDto?.toEntity(),
    );
  }

  @override
  UserEntity? get currentUser => _remoteDataSource.currentUser?.toEntity();

  @override
  Future<Result<UserEntity, AppFailure>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userDto = await _remoteDataSource.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return Result.success(userDto.toEntity());
    } on AuthException catch (e) {
      return Result.failure(_mapAuthException(e));
    } on NetworkException catch (e) {
      return Result.failure(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<UserEntity, AppFailure>> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userDto = await _remoteDataSource.signUpWithEmailAndPassword(
        email: email,
        password: password,
      );
      return Result.success(userDto.toEntity());
    } on AuthException catch (e) {
      return Result.failure(_mapAuthException(e));
    } on NetworkException catch (e) {
      return Result.failure(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<void, AppFailure>> signOut() async {
    try {
      await _remoteDataSource.signOut();
      return const Result.success(null);
    } on AuthException catch (e) {
      return Result.failure(_mapAuthException(e));
    } on NetworkException catch (e) {
      return Result.failure(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  AppFailure _mapAuthException(AuthException e) {
    return switch (e.code) {
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' => const AuthFailure('Invalid email or password'),
      'email-already-in-use' => const AuthFailure(
        'An account with this email already exists',
      ),
      'too-many-requests' => const AuthFailure(
        'Too many attempts. Please try again later',
      ),
      _ => AuthFailure(
        e.message.isNotEmpty ? e.message : 'Authentication failed',
      ),
    };
  }
}
