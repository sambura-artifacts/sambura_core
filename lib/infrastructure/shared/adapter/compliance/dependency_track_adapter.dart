import 'dart:convert';
import 'package:sambura_core/application/compliance/ports/compliance_port.dart';
import 'package:sambura_core/application/shared/ports/http_client_port.dart';

class DependencyTrackAdapter implements CompliancePort {
  final HttpClientPort _client;
  final String _baseUrl;
  final String _apiKey;

  DependencyTrackAdapter(this._client, this._baseUrl, this._apiKey);

  @override
  Future<void> ingestArtifact({
    required String name,
    required String version,
    required String ecosystem,
    required String metadata,
  }) async {
    final bom = {
      "bomFormat": "CycloneDX",
      "specVersion": "1.4",
      "components": [
        {
          "name": name,
          "version": version,
          "purl": "pkg:$ecosystem/$name@$version",
        },
      ],
    };

    await _client.post(
      uri: '$_baseUrl/api/v1/bom',
      headers: {'X-Api-Key': _apiKey, 'Content-Type': 'application/json'},
      data: jsonEncode({
        "projectName": name,
        "projectVersion": version,
        "autoCreate": true,
        "bom": base64Encode(utf8.encode(jsonEncode(bom))),
      }),
    );
  }
}
