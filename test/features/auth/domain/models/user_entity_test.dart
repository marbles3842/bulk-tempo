import 'package:flutter_test/flutter_test.dart';
import 'package:bulk_tempo/features/auth/domain/models/user_entity.dart';

void main() {
  group('UserEntity', () {
    const user1 = UserEntity(
      id: 'uid_1',
      email: 'test@example.com',
      displayName: 'Test User',
    );

    const user2 = UserEntity(
      id: 'uid_1',
      email: 'test@example.com',
      displayName: 'Test User',
    );

    const user3 = UserEntity(
      id: 'uid_2',
      email: 'test2@example.com',
      displayName: 'Other User',
    );

    test('value equality holds for identical properties', () {
      expect(user1, equals(user2));
      expect(user1.hashCode, equals(user2.hashCode));
    });

    test('inequality holds for differing properties', () {
      expect(user1, isNot(equals(user3)));
      expect(user1.hashCode, isNot(equals(user3.hashCode)));
    });

    test('copyWith updates specified fields only', () {
      final updated = user1.copyWith(displayName: 'New Name');
      expect(updated.id, 'uid_1');
      expect(updated.email, 'test@example.com');
      expect(updated.displayName, 'New Name');

      final updatedEmail = user1.copyWith(email: 'new@example.com');
      expect(updatedEmail.id, 'uid_1');
      expect(updatedEmail.email, 'new@example.com');
      expect(updatedEmail.displayName, 'Test User');
    });

    test('copyWith with no arguments retains original values', () {
      final identicalCopy = user1.copyWith();
      expect(identicalCopy, equals(user1));
    });

    test('toString returns descriptive representation', () {
      expect(
        user1.toString(),
        'UserEntity(id: uid_1, email: test@example.com, displayName: Test User)',
      );
    });
  });
}
