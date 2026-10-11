import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bulk_tempo/core/errors/exceptions.dart';
import 'package:bulk_tempo/features/workout/data/datasources/hevy_key_local_data_source.dart';

import '../../../../test_helpers/mocks.dart';

void main() {
  late MockFlutterSecureStorage mockSecureStorage;
  late HevyKeyLocalDataSourceImpl dataSource;

  const validKey = 'f4352809-838a-4e2c-98bb-922f1f14e552';

  setUp(() {
    mockSecureStorage = MockFlutterSecureStorage();
    dataSource = HevyKeyLocalDataSourceImpl(mockSecureStorage);
  });

  group('HevyKeyLocalDataSourceImpl', () {
    test(
      'readApiKey reads from hevy_api_key_<userId> and trims whitespace',
      () async {
        when(() => mockSecureStorage.read(key: 'hevy_api_key_user_1'))
            .thenAnswer((_) async => '  $validKey  ');

        final result = await dataSource.readApiKey(userId: 'user_1');
        expect(result, validKey);
        verify(() => mockSecureStorage.read(key: 'hevy_api_key_user_1'))
            .called(1);
      },
    );

    test('readApiKey returns null when key is missing or whitespace', () async {
      when(() => mockSecureStorage.read(key: 'hevy_api_key_user_1'))
          .thenAnswer((_) async => null);
      when(() => mockSecureStorage.read(key: 'hevy_api_key_user_2'))
          .thenAnswer((_) async => '   ');

      expect(await dataSource.readApiKey(userId: 'user_1'), isNull);
      expect(await dataSource.readApiKey(userId: 'user_2'), isNull);
    });

    test(
      'writeApiKey writes trimmed value under hevy_api_key_<userId>',
      () async {
        when(
          () => mockSecureStorage.write(
            key: 'hevy_api_key_user_1',
            value: validKey,
          ),
        ).thenAnswer((_) async {});

        await dataSource.writeApiKey(userId: 'user_1', apiKey: '  $validKey ');

        verify(
          () => mockSecureStorage.write(
            key: 'hevy_api_key_user_1',
            value: validKey,
          ),
        ).called(1);
      },
    );

    test('deleteApiKey deletes hevy_api_key_<userId>', () async {
      when(() => mockSecureStorage.delete(key: 'hevy_api_key_user_1'))
          .thenAnswer((_) async {});

      await dataSource.deleteApiKey(userId: 'user_1');

      verify(() => mockSecureStorage.delete(key: 'hevy_api_key_user_1'))
          .called(1);
    });

    test(
      'wraps storage exceptions in CacheException for read, write, and delete',
      () async {
        when(() => mockSecureStorage.read(key: any(named: 'key')))
            .thenThrow(Exception('Keychain locked'));
        when(
          () => mockSecureStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          ),
        ).thenThrow(Exception('Keychain write failed'));
        when(() => mockSecureStorage.delete(key: any(named: 'key')))
            .thenThrow(Exception('Keychain delete failed'));

        expect(
          () => dataSource.readApiKey(userId: 'user_1'),
          throwsA(isA<CacheException>()),
        );
        expect(
          () => dataSource.writeApiKey(userId: 'user_1', apiKey: validKey),
          throwsA(isA<CacheException>()),
        );
        expect(
          () => dataSource.deleteApiKey(userId: 'user_1'),
          throwsA(isA<CacheException>()),
        );
      },
    );
  });
}
