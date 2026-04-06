enum RepositoryType { npm }

class NamespaceEntity {
  final int? id; // ID serial do Postgres
  final String packageManager;
  final String name; // Nome amigável (ex: "production-main")
  final String escope; // O dono/escopo (ex: "minha-empresa")
  final bool isPublic; // Se qualquer um pode baixar sem token
  final String
  remoteUrl; // URL do repositório real (ex: "https://registry.npmjs.org/")
  final DateTime? createdAt; // Timestamp de criação

  NamespaceEntity._({
    this.id,
    required this.packageManager,
    required this.name,
    required this.escope,
    required this.isPublic,
    required this.remoteUrl,
    this.createdAt,
  });

  /// Factory para criar um repositório novo no sistema (via API de Admin)
  factory NamespaceEntity.create({
    required String packageManager,
    required String name,
    required String escope,
    bool isPublic = false,
    bool active = true,
    required String remoteUrl,
  }) {
    return NamespaceEntity._(
      packageManager: packageManager,
      name: name,
      escope: escope,
      isPublic: isPublic,
      remoteUrl: remoteUrl,
      createdAt: DateTime.now(),
    );
  }

  factory NamespaceEntity.fromMap(Map<String, dynamic> map) {
    return NamespaceEntity._(
      id: map['id'] is int ? map['id'] as int : null,
      packageManager: map['package_manager'] as String,
      name: map['name'] as String,
      escope: (map['escope'] ?? 'default') as String,
      isPublic: map['is_public'] ?? map['isPublic'] ?? false,
      remoteUrl: map['remote_url'] as String,
      createdAt: map['created_at'] != null
          ? (map['created_at'] is DateTime
                ? map['created_at'] as DateTime
                : DateTime.parse(map['created_at'].toString()))
          : null,
    );
  }

  NamespaceEntity copyWith({
    int? id,
    String? packageManager,
    String? name,
    String? escope,
    bool? isPublic,
    String? remoteUrl,
  }) {
    return NamespaceEntity._(
      id: id ?? this.id,
      packageManager: packageManager ?? this.packageManager,
      name: name ?? this.name,
      escope: escope ?? this.escope,
      isPublic: isPublic ?? this.isPublic,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      createdAt: createdAt,
    );
  }

  // Helper para facilitar a vida nos UseCases e Controllers
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'package_manager': packageManager,
      'name': name,
      'escope': escope,
      'is_public': isPublic,
      'remote_url': remoteUrl,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
