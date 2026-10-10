import 'package:firebase_auth/firebase_auth.dart';
import 'package:bulk_tempo/features/auth/domain/models/user_entity.dart';

class UserDto {
  final String id;
  final String email;
  final String? displayName;

  const UserDto({required this.id, required this.email, this.displayName});

  factory UserDto.fromFirebaseUser(User user) {
    return UserDto(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
    );
  }

  factory UserDto.fromEntity(UserEntity entity) {
    return UserDto(
      id: entity.id,
      email: entity.email,
      displayName: entity.displayName,
    );
  }

  UserEntity toEntity() {
    return UserEntity(id: id, email: email, displayName: displayName);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserDto &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          displayName == other.displayName;

  @override
  int get hashCode => id.hashCode ^ email.hashCode ^ displayName.hashCode;

  @override
  String toString() =>
      'UserDto(id: $id, email: $email, displayName: $displayName)';
}
