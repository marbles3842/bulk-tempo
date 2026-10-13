import 'package:firebase_auth/firebase_auth.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:bulk_tempo/features/auth/domain/models/user_entity.dart';

part 'user_dto.freezed.dart';
part 'user_dto.g.dart';

@freezed
abstract class UserDto with _$UserDto {
  const UserDto._();

  const factory UserDto({
    required String id,
    required String email,
    String? displayName,
  }) = _UserDto;

  factory UserDto.fromJson(Map<String, dynamic> json) =>
      _$UserDtoFromJson(json);

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
}
