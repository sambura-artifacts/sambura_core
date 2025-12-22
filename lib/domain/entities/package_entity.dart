class PackageEntity {
  final int? id; // Identificador único interno no Postgres
  final int? repositoryId; // Vínculo com o repositório pai (namespace)
  final String name; // Nome nominal do pacote (ex: "core-api")
  final String? description; // Metadados descritivos do software
  final DateTime createdAt; // Registro temporal de criação do catálogo

  PackageEntity._({
    this.id,
    this.repositoryId,
    required this.name,
    this.description,
    required this.createdAt,
  });

  /// Instancia um novo pacote para o domínio.
  /// Utilizado quando a API precisa representar um catálogo que será
  /// processado ou validado antes da persistência final pelo Worker.
  factory PackageEntity.create({
    required String name,
    int? repositoryId,
    String? description,
  }) {
    return PackageEntity._(
      repositoryId: repositoryId,
      name: name,
      description: description,
      createdAt: DateTime.now(),
    );
  }

  /// Reconstrói a entidade a partir de um mapeamento de dados (Data Map).
  /// Ideal para consumo de resultados vindos da camada de Infrastructure (SQL).
  factory PackageEntity.fromMap(Map<String, dynamic> map) {
    return PackageEntity._(
      id: map['id'] as int?,
      repositoryId: map['repository_id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      createdAt: map['created_at'] is DateTime
          ? map['created_at']
          : DateTime.parse(map['created_at'].toString()),
    );
  }

  static PackageEntity restore(
    int id,
    int repositoryId,
    String name,
    String description,
    DateTime createdAt,
  ) {
    return PackageEntity._(
      id: id,
      repositoryId: repositoryId,
      name: name,
      description: description,
      createdAt: createdAt,
    );
  }

  /// Converte a entidade em uma estrutura JSON.
  /// Utilizado para respostas da API ou transferência entre camadas.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'repository_id': repositoryId,
      'name': name,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Acessores rápidos para facilitar a leitura no domínio
  int? get packageId => id;
  String get packageName => name;
}
