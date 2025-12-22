class RepositoryEntity {
  final int? id; // ID serial do Postgres
  final String name; // Nome amigável (ex: "production-main")
  final String namespace; // O dono/escopo (ex: "minha-empresa")
  final bool isPublic; // Se qualquer um pode baixar sem token
  final DateTime? createdAt;

  RepositoryEntity._({
    this.id,
    required this.name,
    required this.namespace,
    required this.isPublic,
    this.createdAt,
  });

  /// Factory para criar um repositório novo no sistema (via API de Admin)
  factory RepositoryEntity.create({
    required String name,
    required String namespace,
    bool isPublic = false,
  }) {
    return RepositoryEntity._(
      name: name,
      namespace: namespace,
      isPublic: isPublic,
      createdAt: DateTime.now(),
    );
  }

  factory RepositoryEntity.fromMap(Map<String, dynamic> map) {
    return RepositoryEntity._(
      id: map['id'] is int ? map['id'] as int : null,
      name: map['name'] as String,
      // AJUSTE: Use 'namespace' em vez de 'type'
      namespace: (map['namespace'] ?? map['type'] ?? 'default') as String,
      // AJUSTE: Use 'is_public' (como vem do JSON/DB) para o 'isPublic'
      isPublic: map['is_public'] ?? map['isPublic'] ?? false,
      createdAt: map['created_at'] != null
          ? (map['created_at'] is DateTime
                ? map['created_at'] as DateTime
                : DateTime.parse(map['created_at'].toString()))
          : null,
    );
  }

  RepositoryEntity copyWith({
    int? id,
    String? name,
    String? namespace,
    bool? isPublic,
  }) {
    return RepositoryEntity._(
      id: id ?? this.id,
      name: name ?? this.name,
      namespace: namespace ?? this.namespace,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt,
    );
  }

  // Helper para facilitar a vida nos UseCases e Controllers
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'namespace': namespace,
      'is_public': isPublic,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
