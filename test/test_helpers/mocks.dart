import 'package:firebase_auth/firebase_auth.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bulk_tempo/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:bulk_tempo/features/auth/domain/repositories/auth_repository.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockUser extends Mock implements User {}

class MockUserCredential extends Mock implements UserCredential {}

class MockAuthRepository extends Mock implements AuthRepository {}
