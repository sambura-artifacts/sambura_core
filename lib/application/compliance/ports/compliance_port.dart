/// Port para integração com sistemas de compliance e análise de segurança
/// Segue o padrão Strategy Pattern, delegando a extração de metadados para MetadataExtractor
abstract class CompliancePort {
  /// Realiza a ingestão de um artefato para análise de vulnerabilidades.
  ///
  /// [name] O nome identificador do pacote (ex: 'express' ou 'sambura_core').
  /// [version] A versão semântica do artefato.
  /// [ecosystem] O ecossistema detectado pelo extractor (ex: 'npm', 'maven').
  /// [metadata] O conteúdo bruto dos metadados extraídos (ex: JSON do package.json).
  ///
  /// Lógica de implementação esperada:
  /// 1. Gerar um SBOM (Software Bill of Materials) no formato CycloneDX.
  /// 2. Resolver o PURL (Package URL) seguindo o padrão `pkg:[ecosystem]/[name]@[version]`.
  /// 3. Enviar via POST para a API de auditoria.
  Future<void> ingestArtifact({
    required String name,
    required String version,
    required String ecosystem,
    required String metadata,
  });
}
