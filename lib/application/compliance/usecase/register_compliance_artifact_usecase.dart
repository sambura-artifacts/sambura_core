import 'package:sambura_core/application/compliance/extractor/metadata_extractor.dart';
import 'package:sambura_core/application/compliance/ports/compliance_port.dart';
import 'package:sambura_core/config/logger.dart';

class RegisterComplianceArtifactUseCase {
  final CompliancePort _compliancePort;
  final List<MetadataExtractor> _extractors;

  RegisterComplianceArtifactUseCase(this._compliancePort, this._extractors);

  Future<void> execute({
    required String name,
    required String version,
    required String filename, // Usado para o canHandle
    required List<int> bytes,
  }) async {
    try {
      final extractor = _extractors.firstWhere(
        (e) => e.canHandle(filename),
        orElse: () =>
            throw Exception('Nenhum extrator suporta o arquivo: $filename'),
      );

      final metadata = await extractor.extractPackageMetadata(bytes);

      if (metadata != null) {
        await _compliancePort.ingestArtifact(
          name: name,
          version: version,
          ecosystem: extractor.getPurlNamespace(name),
          metadata: metadata,
        );
      }
    } catch (e, stack) {
      LoggerConfig.getLogger(
        'RegisterComplianceArtifactUseCase',
      ).severe('Falha no processo de compliance do artefato', e, stack);
    }
  }
}
