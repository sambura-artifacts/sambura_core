/// Data Transfer Object (DTO) para entrada de novos artefatos.
/// Centraliza os metadados necessários antes do processamento do binário.
class InfraestructureArtifactInput {
  final String namespace; // ex: npm-private
  final String packageName; // ex: core-lib ou @scope/core-lib
  String? remoteUrl;
  String? packageManager; // ex: NPM, MAVEN...
  String? version; // ex: 1.0.0
  String?
  fileName; // Nome original do arquivo (opcional, ex: core-lib-1.0.0.tgz)
  Map<String, dynamic> metadata; // Metadados específicos do tipo de repo

  InfraestructureArtifactInput({
    required this.namespace,
    required this.packageName,
    this.remoteUrl,
    this.packageManager,
    this.version,
    this.fileName,
    this.metadata = const {},
  });

  /// Retorna uma instância limpa para evitar falhas no MinIO e Upstream
  InfraestructureArtifactInput sanitize() {
    // 1. Decode de scoped packages: @scope%2fpackage -> @scope/package
    String cleanPackage = Uri.decodeComponent(packageName.trim());
    String cleanVersion = ''; // Remove 'v' de v1.0.0
    String cleaRemoteUrl = '';
    // 2. Limpeza de barras redundantes
    cleanPackage = cleanPackage.replaceAll(RegExp(r'^/+'), '');

    // 4. Se o fileName não existir, gera um padrão NPM
    // Ex: @scope/lib-1.0.0.tgz
    String? finalFileName = fileName?.trim();
    if (finalFileName == null || finalFileName.isEmpty) {
      final nameOnly = cleanPackage.contains('/')
          ? cleanPackage.split('/').last
          : cleanPackage;
      finalFileName = '$nameOnly-$cleanVersion.tgz';
    }
    if (remoteUrl != null) {
      cleaRemoteUrl = remoteUrl!.endsWith('/')
          ? remoteUrl!.substring(0, remoteUrl!.length - 1)
          : remoteUrl!;
    }

    return InfraestructureArtifactInput(
      namespace: namespace.trim().toLowerCase(),
      remoteUrl: cleaRemoteUrl,
      packageName: cleanPackage,
      version: cleanVersion,
      fileName: finalFileName,
      metadata: metadata,
    );
  }
}
