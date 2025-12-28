/// Port para integração com sistemas de compliance e análise de segurança
/// Segue o padrão Strategy Pattern, delegando a extração de metadados para MetadataExtractor
abstract class CompliancePort {
  /// Registra um artefato no sistema de compliance usando metadados extraídos
  ///
  /// [packageMetadata] - JSON string contendo metadados do pacote (ex: package.json)
  /// [purlNamespace] - Namespace do Package URL (ex: 'npm', 'maven', 'pypi')
  /// [name] - Nome do pacote
  /// [version] - Versão do pacote
  Future<void> registerArtifact({
    required String packageMetadata,
    required String purlNamespace,
    required String name,
    required String version,
  });
}
