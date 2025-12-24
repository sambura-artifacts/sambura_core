import 'dart:async';
import 'dart:typed_data';

/// Port (Interface) para serviço de armazenamento de blobs.
///
/// Seguindo o princípio de Inversão de Dependência (DIP),
/// esta interface define o contrato que qualquer adapter de storage deve implementar.
/// Permite trocar facilmente entre MinIO, S3, FileSystem, etc.
abstract class StoragePort {
  /// Armazena um stream de bytes no storage.
  ///
  /// [path] - Caminho lógico do objeto
  /// [stream] - Stream de bytes a ser armazenado
  /// [sizeBytes] - Tamanho total em bytes
  /// [contentType] - MIME type do conteúdo
  Future<void> store({
    required String path,
    required Stream<Uint8List> stream,
    required int sizeBytes,
    String contentType = 'application/octet-stream',
  });

  /// Recupera um objeto como stream de bytes.
  ///
  /// [path] - Caminho lógico do objeto
  /// Returns: Stream de bytes do objeto
  /// Throws: Exception se o objeto não existir
  Future<StreamView<List<int>>> retrieve(String path);

  /// Verifica se um objeto existe no storage.
  ///
  /// [path] - Caminho lógico do objeto
  /// Returns: true se existe, false caso contrário
  Future<bool> exists(String path);

  /// Remove um objeto do storage.
  ///
  /// [path] - Caminho lógico do objeto
  Future<void> delete(String path);

  /// Obtém metadados de um objeto.
  ///
  /// [path] - Caminho lógico do objeto
  /// Returns: Map com metadados (size, contentType, etc)
  Future<Map<String, dynamic>> getMetadata(String path);

  Future<bool> isHealthy();
}
