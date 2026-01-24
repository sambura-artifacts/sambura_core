class ApiKeyEntity {
  final int? id;
  final int accountId;
  final String name;
  final String keyHash;
  final String prefix;
  final DateTime? createdAt;
  final DateTime? lastUsedAt;
  final DateTime? expiresAt;

  ApiKeyEntity({
    this.id,
    required this.accountId,
    required this.name,
    required this.keyHash,
    required this.prefix,
    this.createdAt,
    this.lastUsedAt,
    this.expiresAt,
  });

  ApiKeyEntity copyWith({
    int? id,
    int? accountId,
    String? name,
    String? keyHash,
    String? prefix,
    DateTime? expiresAt,
    DateTime? lastUsedAt,
    DateTime? createdAt,
  }) {
    return ApiKeyEntity(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      name: name ?? this.name,
      keyHash: keyHash ?? this.keyHash,
      prefix: prefix ?? this.prefix,
      expiresAt: expiresAt ?? this.expiresAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return expiresAt!.isBefore(DateTime.now());
  }
}
