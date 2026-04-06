class ApplicationArtifactInput {
  final String packageManager;
  final String remoteUrl;
  final String namespace;
  final String packageName;
  final String version;
  final String? fileName;
  final Map<String, dynamic> metadata;

  ApplicationArtifactInput({
    required this.packageManager,
    required this.remoteUrl,
    required this.namespace,
    required this.packageName,
    required this.version,
    this.fileName,
    this.metadata = const {},
  }) {
    _validate();
  }

  void _validate() {
    if (namespace.trim().isEmpty) {
      throw ArgumentError('namespace é obrigatório');
    }
    if (packageName.trim().isEmpty) {
      throw ArgumentError('packageName é obrigatório');
    }
    if (version.trim().isEmpty) {
      throw ArgumentError('version é obrigatória');
    }

    // Impede injeção de paths no nome do pacote ou versão
    final invalidChars = RegExp(r'[<>:"|?*]');
    if (invalidChars.hasMatch(packageName) || invalidChars.hasMatch(version)) {
      throw ArgumentError(
        'Caracteres inválidos detectados no pacote ou versão',
      );
    }
  }

  /// Retorna uma instância limpa para evitar falhas no MinIO e Upstream
  ApplicationArtifactInput sanitize() {
    // 1. Decode de scoped packages: @scope%2fpackage -> @scope/package
    String cleanPackage = Uri.decodeComponent(packageName.trim());

    // 2. Limpeza de barras redundantes
    cleanPackage = cleanPackage.replaceAll(RegExp(r'^/+'), '');
    String cleanVersion = version.trim().replaceAll(
      RegExp(r'^v'),
      '',
    ); // Remove 'v' de v1.0.0

    // 3. Normalização da URL Remota
    String cleanRemote = remoteUrl.trim();
    if (cleanRemote.endsWith('/')) {
      cleanRemote = cleanRemote.substring(0, cleanRemote.length - 1);
    }

    // 4. Se o fileName não existir, gera um padrão NPM
    // Ex: @scope/lib-1.0.0.tgz
    String? finalFileName = fileName?.trim();
    if (finalFileName == null || finalFileName.isEmpty) {
      final nameOnly = cleanPackage.contains('/')
          ? cleanPackage.split('/').last
          : cleanPackage;
      finalFileName = '$nameOnly-$cleanVersion.tgz';
    }

    return ApplicationArtifactInput(
      packageManager: packageManager,
      remoteUrl: cleanRemote,
      namespace: namespace.trim().toLowerCase(),
      packageName: cleanPackage,
      version: cleanVersion,
      fileName: finalFileName,
      metadata: metadata,
    );
  }

  /// Gera o path único para o Storage (MinIO)
  /// Ex: npm/public/@types/node/node-1.0.0.tgz
  String buildStoragePath(String projectType) {
    return '$projectType/$namespace/$packageName/$fileName';
  }
}
