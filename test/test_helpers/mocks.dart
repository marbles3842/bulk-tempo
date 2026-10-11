import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:bulk_tempo/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:bulk_tempo/features/auth/domain/repositories/auth_repository.dart';
import 'package:bulk_tempo/features/gain_target/data/datasources/gain_target_remote_data_source.dart';
import 'package:bulk_tempo/features/gain_target/domain/repositories/gain_target_repository.dart';
import 'package:bulk_tempo/features/weight/data/datasources/weight_remote_data_source.dart';
import 'package:bulk_tempo/features/weight/domain/repositories/weight_repository.dart';
import 'package:bulk_tempo/features/workout/data/datasources/hevy_key_local_data_source.dart';
import 'package:bulk_tempo/features/workout/data/datasources/workout_remote_data_source.dart';
import 'package:bulk_tempo/features/workout/domain/repositories/workout_repository.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockUser extends Mock implements User {}

class MockUserCredential extends Mock implements UserCredential {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockFirebaseDatabase extends Mock implements FirebaseDatabase {}

class MockDatabaseReference extends Mock implements DatabaseReference {}

class MockDataSnapshot extends Mock implements DataSnapshot {}

class MockWeightRemoteDataSource extends Mock
    implements WeightRemoteDataSource {}

class MockWeightRepository extends Mock implements WeightRepository {}

class MockGainTargetRemoteDataSource extends Mock
    implements GainTargetRemoteDataSource {}

class MockGainTargetRepository extends Mock implements GainTargetRepository {}

class MockHttpClient extends Mock implements http.Client {}

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

class MockHevyKeyLocalDataSource extends Mock
    implements HevyKeyLocalDataSource {}

class MockWorkoutRemoteDataSource extends Mock
    implements WorkoutRemoteDataSource {}

class MockWorkoutRepository extends Mock implements WorkoutRepository {}
