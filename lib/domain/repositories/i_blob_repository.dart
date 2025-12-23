import 'package:sambura_core/domain/entities/blob_entity.dart';
import 'package:sambura_core/domain/value_objects/hash.dart';

/// Interface para operações de escrita de blobs.
abstract class IBlobWriteRepository {
  /// Armazena um novo blob.
  Future<BlobEntity> save(BlobEntity blob);

  /// Remove um blob (geralmente não usado devido a deduplicação).
  Future<void> delete(Hash hash);
}

/// Interface para operações de leitura de blobs.
abstract class IBlobReadRepository {
  /// Busca blob por hash.
  Future<BlobEntity?> findByHash(Hash hash);

  /// Retorna stream de bytes do blob.
  Future<Stream<List<int>>> readAsStream(Hash hash);

  /// Verifica se um blob existe.
  Future<bool> exists(Hash hash);

  /// Obtém tamanho de um blob.
  Future<int> getSize(Hash hash);
}

/// Interface para estatísticas de blobs.
abstract class IBlobStatsRepository {
  /// Calcula espaço total usado por blobs.
  Future<int> getTotalSize();

  /// Conta quantos blobs existem.
  Future<int> count();

  /// Lista blobs órfãos (sem referência de artefatos).
  Future<List<Hash>> findOrphans();

  /// Busca blobs duplicados (apenas metadados, mesma função da dedup).
  Future<Map<Hash, int>> findDuplicates();
}
