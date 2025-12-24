/// Port (Interface) para proxy de registries externos (NPM, PyPI, Maven, etc).
///
/// Define o contrato para buscar e cachear pacotes de registries upstream.
abstract class RegistryProxyPort {
  /// Busca metadados de um pacote no registry externo.
  ///
  /// [packageName] - Nome do pacote
  /// Returns: Metadados do pacote ou null se não encontrado
  Future<Map<String, dynamic>?> fetchPackageMetadata(String packageName);

  /// Busca uma versão específica de um pacote.
  ///
  /// [packageName] - Nome do pacote
  /// [version] - Versão desejada
  /// Returns: Stream de bytes do artefato
  Future<Stream<List<int>>?> fetchArtifact(String packageName, String version);

  /// Verifica se um pacote existe no registry externo.
  ///
  /// [packageName] - Nome do pacote
  /// Returns: true se existe
  Future<bool> packageExists(String packageName);

  /// Lista todas as versões disponíveis de um pacote.
  ///
  /// [packageName] - Nome do pacote
  /// Returns: Lista de versões
  Future<List<String>> listVersions(String packageName);
}
