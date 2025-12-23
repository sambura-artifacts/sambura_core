import 'dart:async';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:convert/convert.dart';
import 'package:mime/mime.dart';
import 'package:sambura_core/domain/repositories/blob_repository.dart';

class BlobEntity {
  final int? id; // ID serial (gerado pelo Worker no DB)
  final String hashValue; // SHA-256 (Identidade única do arquivo)
  final int sizeBytes; // Tamanho real em disco
  final String mimeType; // Tipo do arquivo (ex: application/zip)
  final DateTime? createdAt;

  BlobEntity._({
    this.id,
    required this.hashValue,
    required this.sizeBytes,
    required this.mimeType,
    this.createdAt,
  });

  factory BlobEntity.create({
    required String hash,
    required int size,
    required String mime,
  }) {
    return BlobEntity._(hashValue: hash, sizeBytes: size, mimeType: mime);
  }

  /// Ponto de entrada para processar um binário e gerar a entidade BlobEntity.
  ///
  /// Este método lê o [byteStream] uma única vez, calculando o SHA-256
  /// e o tamanho total sem carregar o arquivo inteiro na memória RAM.
  // lib/domain/entities/blob_entity.dart
  static Future<BlobEntity> fromStream(Stream<List<int>> stream) async {
    final hashOutput = AccumulatorSink<Digest>();
    final inputSink = sha256.startChunkedConversion(hashOutput);

    int totalBytes = 0;
    List<int> headerBytes = []; // Vamos guardar o início aqui

    try {
      await for (final chunk in stream) {
        final safeChunk = Uint8List.fromList(chunk);

        // Captura apenas o necessário para o MimeTypeResolver (geralmente 32-64 bytes)
        if (headerBytes.length < 64) {
          headerBytes.addAll(safeChunk.take(64 - headerBytes.length));
        }

        totalBytes += safeChunk.length;
        inputSink.add(safeChunk);
      }

      inputSink.close();

      // Chamada síncrona e segura, sem mexer em stream nenhum!
      final detectedMime = _detectRealMimeType(headerBytes);

      return BlobEntity._(
        hashValue: hashOutput.events.single.toString(),
        sizeBytes: totalBytes,
        mimeType: detectedMime,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Stream<List<int>>> toStream(BlobRepository storage) async {
    return storage.readAsStream(hashValue);
  }

  factory BlobEntity.restore(
    int id,
    String hash,
    int size,
    String mime,
    DateTime createdAt,
  ) {
    return BlobEntity._(
      id: id,
      hashValue: hash,
      sizeBytes: size,
      mimeType: mime,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {'hash': hashValue, 'size': sizeBytes, 'mime': mimeType};
  }

  factory BlobEntity.fromMap(Map<String, dynamic> map) {
    return BlobEntity._(
      id: map['id'] as int?,
      hashValue: (map['hash_value'] ?? '') as String,
      sizeBytes: map['size_bytes'] as int,
      mimeType: (map['mime_type'] ?? 'application/octet-stream') as String,
      createdAt: map['created_at'] != null
          ? (map['created_at'] is DateTime
                ? map['created_at'] as DateTime
                : DateTime.parse(map['created_at'] as String))
          : null,
    );
  }
  static String _detectRealMimeType(List<int> headerBytes) {
    if (headerBytes.isEmpty) return 'application/octet-stream';

    final resolver = MimeTypeResolver();
    final mimeType = resolver.lookup('', headerBytes: headerBytes);

    return mimeType ?? 'application/octet-stream';
  }
}
