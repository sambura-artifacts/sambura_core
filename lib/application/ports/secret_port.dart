/// Port (Interface) para serviço de gerenciamento de segredos.
///
/// Define o contrato para acesso a segredos sensíveis.
/// Pode ser implementado com HashiCorp Vault, AWS Secrets Manager, etc.
abstract class ISecretPort {
  /// Recupera um conjunto de segredos de um caminho específico.
  ///
  /// [path] - Caminho do segredo (ex: "sambura/database")
  /// Returns: Map com os segredos ou Map vazio se não encontrado
  Future<Map<String, dynamic>> getSecrets(String path);

  /// Recupera um segredo específico.
  ///
  /// [path] - Caminho do segredo
  /// [key] - Chave específica dentro do segredo
  /// Returns: Valor do segredo ou null se não encontrado
  Future<String?> getSecret(String path, String key);

  /// Armazena ou atualiza um conjunto de segredos.
  ///
  /// [path] - Caminho onde armazenar
  /// [secrets] - Map com os segredos
  Future<void> putSecrets(String path, Map<String, dynamic> secrets);

  /// Remove um segredo.
  ///
  /// [path] - Caminho do segredo a remover
  Future<void> deleteSecret(String path);

  /// Verifica se um segredo existe.
  ///
  /// [path] - Caminho do segredo
  /// Returns: true se existe
  Future<bool> exists(String path);
}
