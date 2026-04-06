class ArtifactMetadataInput {
  final String projectType;
  final String repositoryName;
  final String packageName;
  final Map<String, String> requestHeaders;

  ArtifactMetadataInput({
    required this.projectType,
    required this.repositoryName,
    required this.packageName,
    required this.requestHeaders,
  }) {
    _validate();
  }

  void _validate() {
    if (projectType.trim().isEmpty) {
      throw ArgumentError('projectType não pode ser vazio');
    }
    if (repositoryName.trim().isEmpty) {
      throw ArgumentError('repositoryName não pode ser vazio');
    }
    if (packageName.trim().isEmpty) {
      throw ArgumentError('packageName não pode ser vazio');
    }

    // Validação de segurança: Impede Path Traversal (evita ../ no nome do pacote)
    if (packageName.contains('..') || packageName.contains('\\')) {
      throw ArgumentError(
        'packageName contém caracteres inválidos ou tentativa de path traversal',
      );
    }
  }

  /// Cria uma instância sanitizada pronta para o Use Case.
  /// Resolve o problema de pacotes com scope (@types/node) e espaços.
  ArtifactMetadataInput sanitize() {
    // 1. Decodifica o nome do pacote caso venha encodado da URL do Shelf
    // Ex: @types%2fnode -> @types/node
    String decodedPackage = Uri.decodeComponent(packageName.trim());

    // 2. Garante que pacotes scoped não tenham barras duplicadas no início
    decodedPackage = decodedPackage.replaceAll(RegExp(r'^/+'), '');

    return ArtifactMetadataInput(
      projectType: projectType.trim().toLowerCase(),
      repositoryName: repositoryName.trim(),
      packageName: decodedPackage,
      requestHeaders: requestHeaders.map(
        (key, value) => MapEntry(key.toLowerCase().trim(), value.trim()),
      ),
    );
  }

  /// Helper para montar a URL de Upstream com segurança
  Uri buildUpstreamUri(String remoteUrl) {
    final cleanBase = remoteUrl.endsWith('/')
        ? remoteUrl.substring(0, remoteUrl.length - 1)
        : remoteUrl;

    // O Uri.parse lida corretamente com o @ e / se o packageName estiver limpo
    return Uri.parse('$cleanBase/$packageName');
  }
}
