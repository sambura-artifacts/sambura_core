import 'package:sambura_core/domain/exceptions/exceptions.dart';

class SecurityValidator {
  // Regex para nomes de pacotes NPM (suporta escopos como @sambura/core)
  static final _npmNameRegex = RegExp(
    r'^(@[a-z0-9-~][a-z0-9-._~]*/)?[a-z0-9-~][a-z0-9-._~]*$',
  );

  // Regex para ações de sistema do NPM (ex: -/v1/search)
  static final _npmSystemActionRegex = RegExp(r'^-/[a-z0-9\-/]+$');

  static void validatePackagePath(String path) {
    if (path.contains('..') || path.contains('\\')) {
      throw SecurityException('Sequência de caminho maliciosa detectada.');
    }

    // Decodifica %2F para / para validar escopos corretamente
    final decodedPath = Uri.decodeComponent(path);

    if (decodedPath.startsWith('-/')) {
      if (!_npmSystemActionRegex.hasMatch(decodedPath)) {
        throw SecurityException('Ação de sistema do registro inválida.');
      }
      return;
    }

    String packageName = decodedPath;

    if (decodedPath.endsWith('.tgz')) {
      // No NPM, o tarball é sempre: nome-da-versao.tgz
      // Precisamos remover apenas o final que condiz com a versão
      final versionRegex = RegExp(r'-(\d+\.\d+\.\d+.*)\.tgz$');
      packageName = decodedPath.replaceFirst(versionRegex, '');
    }

    if (!_npmNameRegex.hasMatch(packageName)) {
      throw SecurityException('Nome de pacote inválido: $packageName');
    }
  }

  // Valida se o input contém apenas caracteres seguros (alfanumérico, hífen, underline, ponto e arroba)
  static void validateGenericInput(String input) {
    final safeRegex = RegExp(r'^[a-zA-Z0-9\-\_\.\@\/]+$');
    if (!safeRegex.hasMatch(input)) {
      throw SecurityException('Caracteres inválidos detectados no input.');
    }
  }
}
