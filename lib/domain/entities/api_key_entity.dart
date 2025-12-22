class ApiKeyEntity {
  final int id;
  final int accountId;
  final String name;
  final String keyHash;
  final String prefix;
  final DateTime? lastUsedAt;
  final DateTime? expiresAt;

  ApiKeyEntity({
    required this.id,
    required this.accountId,
    required this.name,
    required this.keyHash,
    required this.prefix,
    this.lastUsedAt,
    this.expiresAt,
  });
}
