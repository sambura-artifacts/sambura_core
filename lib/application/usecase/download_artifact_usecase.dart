import 'dart:async';
import 'package:sambura_core/domain/repositories/blob_repository.dart';

class DownloadArtifactUsecase {
  final BlobRepository _blobRepo;

  DownloadArtifactUsecase(this._blobRepo);

  Future<Stream<List<int>>> execute(String hash) async {
    final blob = await _blobRepo.findByHash(hash);

    if (blob == null) {
      throw Exception('Arquivo com hash $hash não foi encontrado no Samburá.');
    }

    return await _blobRepo.readAsStream(hash);
  }
}
