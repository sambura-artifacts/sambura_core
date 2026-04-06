import 'dart:typed_data';

import 'package:shelf/shelf.dart';
import 'dart:convert';

import 'package:sambura_core/domain/barrel.dart';

class ArtifactPresenter {
  static Response success(ArtifactEntity artifact) {
    final payload = {
      'external_id': artifact.externalId,
      'version': artifact.version,
      'path': artifact.path,
      'size_bytes': artifact.blob?.sizeBytes,
      'sha256': artifact.blob?.hash,
      'mime_type': artifact.blob?.mimeType,
      'created_at': artifact.createdAt.toIso8601String(),
      '_links': {
        'self': {'href': '/${artifact.path}'},
        'download': {'href': '/blobs/${artifact.blob?.hash}'},
      },
    };

    return Response.ok(
      jsonEncode(payload),
      headers: {
        'content-type': 'application/json',
        'x-sambura-version': artifact.version,
      },
    );
  }

  static Response createArtifact(ArtifactEntity artifact, String baseUrl) =>
      Response.ok(
        jsonEncode({
          'message': 'Artefato criado com sucesso!',
          'metadata': {
            'external_id': artifact.externalId,
            'version': artifact.version,
            'path': artifact.path,
            'created_at': artifact.createdAt.toIso8601String(),
          },
          '_links': {
            'self': {
              'href': '$baseUrl/artifacts/${artifact.externalId}',
              'method': 'GET',
            },
            'download': {
              'href': '$baseUrl/blobs/${artifact.blob?.hash}',
              'method': 'GET',
            },
            'package': {
              'href': '$baseUrl/packages/${artifact.packageName}',
              'method': 'GET',
            },
          },
        }),
        headers: {'Content-Type': 'application/json'},
      );

  static Response returnTarballStream(
    Stream<Uint8List> stream,
    String version,
  ) {
    return Response.ok(
      stream,
      headers: {
        'Content-Type': 'application/octet-stream',
        'Content-Disposition': 'attachment; filename="package-$version.tgz"',
        'x-sambura-version': version,
      },
    );
  }
}
