import 'dart:typed_data';

import 'package:sambura_core/domain/entities/blob_entity.dart';

abstract class BlobRepository {
  /// Salva o Blob no banco e garante a deduplicação.
  /// Se o hash já existir, ele deve retornar o [Blob] com o ID
  Future<BlobEntity> save(BlobEntity blob);

  /// Busca um Blob pelo seu Hash único (SHA-256).
  Future<BlobEntity?> findByHash(String hashValue);

  /// Busca um Blob pelo ID interno (Serial).
  Future<BlobEntity?> findById(int id);

  /// Remove o Blob do banco de dados.
  Future<void> delete(int id);

  /// Verifica se um Blob existe no storage físico.
  Future<bool> exists(String hashValue);

  /// Salva o arquivo e retorna os metadados (já temos esse)
  Future<BlobEntity> saveFromStream(Stream<List<int>> byteStream);

  /// NOVO: Abre o arquivo físico para leitura via Stream usando o Hash como chave
  Future<Stream<Uint8List>> readAsStream(String hashValue);
}
