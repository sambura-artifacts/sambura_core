import 'dart:convert';
import 'package:sambura_core/application/compliance/ports/compliance_port.dart';
import 'package:sambura_core/application/shared/ports/ports.dart';

/// Adapter para integração com Dependency-Track
///
/// Implementa CompliancePort e recebe metadados já extraídos,
/// seguindo o princípio de Separação de Responsabilidades (SRP)
class DependencyTrackAdapter implements CompliancePort {
  final HttpClientPort _httpClient;
  final String _baseUrl;
  final String _apiKey;

  DependencyTrackAdapter({
    required HttpClientPort httpClient,
    required String baseUrl,
    required String apiKey,
  }) : _httpClient = httpClient,
       _baseUrl = baseUrl,
       _apiKey = apiKey;

  @override
  Future<void> registerArtifact({
    required String packageMetadata,
    required String purlNamespace,
    required String name,
    required String version,
  }) async {
    // Gera SBOM no formato CycloneDX
    final bom = _generateCycloneDX(
      name: name,
      version: version,
      purlNamespace: purlNamespace,
    );

    final base64Bom = base64Encode(utf8.encode(jsonEncode(bom)));

    // Envia para o Dependency-Track
    await _httpClient.post(
      uri: '$_baseUrl/api/v1/bom',
      headers: {'X-Api-Key': _apiKey, 'Content-Type': 'application/json'},
      data: jsonEncode({
        "projectName": name,
        "projectVersion": version,
        "autoCreate": true,
        "bom": base64Bom,
      }),
    );
  }

  /// Gera SBOM no formato CycloneDX
  Map<String, dynamic> _generateCycloneDX({
    required String name,
    required String version,
    required String purlNamespace,
  }) {
    return {
      "bomFormat": "CycloneDX",
      "specVersion": "1.4",
      "version": 1,
      "components": [
        {
          "name": name,
          "version": version,
          "type": "library",
          "purl": "pkg:$purlNamespace/$name@$version",
        },
      ],
    };
  }
}
