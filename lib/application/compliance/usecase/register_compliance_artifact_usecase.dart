import 'package:logging/logging.dart';
import 'package:sambura_core/application/compliance/extractor/metadata_extractor.dart';
import 'package:sambura_core/application/compliance/ports/compliance_port.dart';
import 'package:sambura_core/config/logger.dart';

/// Use case para registrar artefatos no sistema de compliance
///
/// Orquestra a extração de metadados usando MetadataExtractor apropriado
/// e delega o registro para CompliancePort
class RegisterComplianceArtifactUseCase {
  final List<MetadataExtractor> _extractors;
  final CompliancePort _compliancePort;
  final Logger _log = LoggerConfig.getLogger(
    'RegisterComplianceArtifactUseCase',
  );

  RegisterComplianceArtifactUseCase({
    required List<MetadataExtractor> extractors,
    required CompliancePort compliancePort,
  }) : _extractors = extractors,
       _compliancePort = compliancePort;

  /// Executa o registro de compliance para um artefato
  ///
  /// [filename] - Nome do arquivo do artefato (usado para determinar o extrator apropriado)
  /// [bytes] - Bytes do artefato (tarball, zip, etc)
  /// [name] - Nome do pacote
  /// [version] - Versão do pacote
  Future<void> execute({
    required String filename,
    required List<int> bytes,
    required String name,
    required String version,
  }) async {
    _log.info('🔍 Iniciando registro de compliance: $name@$version');

    try {
      // Encontra o extrator apropriado usando Strategy Pattern
      final extractor = _extractors.firstWhere(
        (e) => e.canHandle(filename),
        orElse: () => throw UnsupportedError(
          'Nenhum extrator disponível para: $filename',
        ),
      );

      _log.fine('Usando extrator: ${extractor.runtimeType}');

      // Extrai metadados do artefato
      final packageMetadata = await extractor.extractPackageMetadata(bytes);

      if (packageMetadata == null) {
        _log.warning('⚠️ Não foi possível extrair metadados de: $filename');
        return;
      }

      _log.fine('✓ Metadados extraídos com sucesso');

      final purlNamespace = extractor.getPurlNamespace(name);

      await _compliancePort.registerArtifact(
        packageMetadata: packageMetadata,
        purlNamespace: purlNamespace,
        name: name,
        version: version,
      );

      _log.info(
        '✅ Artefato registrado no sistema de compliance: $name@$version',
      );
    } catch (e, stack) {
      _log.severe(
        '❌ Erro ao registrar artefato no compliance: $name@$version',
        e,
        stack,
      );
    }
  }
}
