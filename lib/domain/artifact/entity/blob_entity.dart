import 'dart:async';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:convert/convert.dart';
import 'package:mime/mime.dart';
import 'package:sambura_core/domain/repositories/repositories.dart';

class BlobEntity {
  final int? id;
  final String hash;
  final int sizeBytes;
  final String mimeType;
  final DateTime? createdAt;

  BlobEntity._({
    this.id,
    required this.hash,
    required this.sizeBytes,
    required this.mimeType,
    this.createdAt,
  });

  factory BlobEntity.create({
    required String hash,
    required int size,
    required String mime,
  }) {
    return BlobEntity._(hash: hash, sizeBytes: size, mimeType: mime);
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

        if (headerBytes.length < 64) {
          headerBytes.addAll(safeChunk.take(64 - headerBytes.length));
        }

        totalBytes += safeChunk.length;
        inputSink.add(safeChunk);
      }

      inputSink.close();

      final detectedMime = _detectRealMimeType(headerBytes);

      return BlobEntity._(
        hash: hashOutput.events.single.toString(),
        sizeBytes: totalBytes,
        mimeType: detectedMime,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Stream<List<int>>> toStream(BlobRepository storage) async {
    return storage.readAsStream(hash);
  }

  factory BlobEntity.restore({
    required int? id,
    required String hash,
    required int size,
    required String mime,
    required DateTime? createdAt,
  }) {
    return BlobEntity._(
      id: id,
      hash: hash,
      sizeBytes: size,
      mimeType: mime,
      createdAt: createdAt,
    );
  }

  static String _detectRealMimeType(List<int> headerBytes) {
    if (headerBytes.isEmpty) return 'application/octet-stream';

    final resolver = MimeTypeResolver();
    final mimeType = resolver.lookup('', headerBytes: headerBytes);

    return mimeType ?? 'application/octet-stream';
  }
}
