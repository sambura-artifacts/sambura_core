enum RepositoryType { npm, maven, pypi, nuget, docker, generic }

class RepositoryEntity {
  final int? id; // ID serial do Postgres
  final String name; // Nome amigável (ex: "production-main")
  final String namespace; // O dono/escopo (ex: "minha-empresa")
  final bool isPublic; // Se qualquer um pode baixar sem token
  final RepositoryType type; // Tipo do repositório (npm, maven, etc)
  final String
  remoteUrl; // URL do repositório real (ex: "https://registry.npmjs.org/")
  final DateTime? createdAt; // Timestamp de criação

  RepositoryEntity._({
    this.id,
    required this.name,
    required this.namespace,
    required this.isPublic,
    required this.type,
    required this.remoteUrl,
    this.createdAt,
  });

  /// Factory para criar um repositório novo no sistema (via API de Admin)
  factory RepositoryEntity.create({
    required String name,
    required String namespace,
    bool isPublic = false,
    bool active = true,
    RepositoryType type = RepositoryType.generic,
    required String remoteUrl,
  }) {
    return RepositoryEntity._(
      name: name,
      namespace: namespace,
      isPublic: isPublic,
      type: type,
      remoteUrl: remoteUrl,
      createdAt: DateTime.now(),
    );
  }

  factory RepositoryEntity.fromMap(Map<String, dynamic> map) {
    return RepositoryEntity._(
      id: map['id'] is int ? map['id'] as int : null,
      name: map['name'] as String,
      namespace: (map['namespace'] ?? 'default') as String,
      isPublic: map['is_public'] ?? map['isPublic'] ?? false,
      type: RepositoryType.values.firstWhere(
        (e) => e.toString() == 'RepositoryType.${map['type']}',
        orElse: () => RepositoryType.generic,
      ),
      remoteUrl: map['remote_url'] as String,
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
    RepositoryType? type,
    String? remoteUrl,
  }) {
    return RepositoryEntity._(
      id: id ?? this.id,
      name: name ?? this.name,
      namespace: namespace ?? this.namespace,
      isPublic: isPublic ?? this.isPublic,
      type: type ?? this.type,
      remoteUrl: remoteUrl ?? this.remoteUrl,
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
      'type': type.name,
      'remote_url': remoteUrl,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
