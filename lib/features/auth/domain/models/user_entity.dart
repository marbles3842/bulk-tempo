class UserEntity {
  final String id;
  final String email;
  final String? displayName;

  const UserEntity({required this.id, required this.email, this.displayName});

  UserEntity copyWith({String? id, String? email, String? displayName}) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          displayName == other.displayName;

  @override
  int get hashCode => id.hashCode ^ email.hashCode ^ displayName.hashCode;

  @override
  String toString() =>
      'UserEntity(id: $id, email: $email, displayName: $displayName)';
}
