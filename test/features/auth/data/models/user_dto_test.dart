import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bulk_tempo/features/auth/data/models/user_dto.dart';
import 'package:bulk_tempo/features/auth/domain/models/user_entity.dart';

import '../../../../test_helpers/mocks.dart';

void main() {
  group('UserDto', () {
    late MockUser mockFirebaseUser;

    setUp(() {
      mockFirebaseUser = MockUser();
    });

    test('fromFirebaseUser maps all fields correctly', () {
      when(() => mockFirebaseUser.uid).thenReturn('fb_uid_123');
      when(() => mockFirebaseUser.email).thenReturn('user@domain.com');
      when(() => mockFirebaseUser.displayName).thenReturn('Jane Doe');

      final dto = UserDto.fromFirebaseUser(mockFirebaseUser);

      expect(dto.id, 'fb_uid_123');
      expect(dto.email, 'user@domain.com');
      expect(dto.displayName, 'Jane Doe');
    });

    test(
      'fromFirebaseUser handles nullable email with empty string fallback',
      () {
        when(() => mockFirebaseUser.uid).thenReturn('fb_uid_456');
        when(() => mockFirebaseUser.email).thenReturn(null);
        when(() => mockFirebaseUser.displayName).thenReturn(null);

        final dto = UserDto.fromFirebaseUser(mockFirebaseUser);

        expect(dto.id, 'fb_uid_456');
        expect(dto.email, '');
        expect(dto.displayName, isNull);
      },
    );

    test('toEntity converts to UserEntity correctly', () {
      const dto = UserDto(
        id: 'dto_id',
        email: 'dto@test.com',
        displayName: 'Display Name',
      );

      final entity = dto.toEntity();

      expect(entity, isA<UserEntity>());
      expect(entity.id, 'dto_id');
      expect(entity.email, 'dto@test.com');
      expect(entity.displayName, 'Display Name');
    });

    test('fromEntity converts from UserEntity correctly', () {
      const entity = UserEntity(
        id: 'entity_id',
        email: 'entity@test.com',
        displayName: 'Entity Name',
      );

      final dto = UserDto.fromEntity(entity);

      expect(dto.id, 'entity_id');
      expect(dto.email, 'entity@test.com');
      expect(dto.displayName, 'Entity Name');
    });

    test('equality and hashCode hold for identical values', () {
      const dto1 = UserDto(id: '1', email: 'a@b.c', displayName: 'A');
      const dto2 = UserDto(id: '1', email: 'a@b.c', displayName: 'A');
      const dto3 = UserDto(id: '2', email: 'a@b.c', displayName: 'A');

      expect(dto1, equals(dto2));
      expect(dto1.hashCode, equals(dto2.hashCode));
      expect(dto1, isNot(equals(dto3)));
    });

    test('toString formats correctly', () {
      const dto = UserDto(id: '1', email: 'a@b.c', displayName: 'A');
      expect(dto.toString(), 'UserDto(id: 1, email: a@b.c, displayName: A)');
    });
  });
}
