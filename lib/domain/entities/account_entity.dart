class AccountEntity {
  final int? id;
  final String username;
  final String passwordHash;
  final String email;
  final String role;
  final DateTime? createdAt;

  AccountEntity._({
    this.id,
    required this.username,
    required this.passwordHash,
    required this.email,
    required this.role,
    this.createdAt,
  });

  factory AccountEntity.create({
    required String username,
    required String passwordHash,
    required String email,
    String role = 'developer',
  }) {
    return AccountEntity._(
      username: username,
      passwordHash: passwordHash,
      email: email,
      role: role,
    );
  }

  factory AccountEntity.restore({
    required int id,
    required String username,
    required String passwordHash,
    required String email,
    required String role,
    required DateTime createdAt,
  }) {
    return AccountEntity._(
      id: id,
      username: username,
      passwordHash: passwordHash,
      email: email,
      role: role,
      createdAt: createdAt,
    );
  }

  bool get isAdmin => role == 'admin';

  @override
  String toString() =>
      'AccountEntity(id: $id, username: $username, role: $role)';
}
