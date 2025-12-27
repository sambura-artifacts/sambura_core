// lib/domain/utils/security_validator.dart

import 'package:sambura_core/domain/exceptions/security_exception.dart';

class SecurityValidator {
  // Regex que permite hífens e pontos (comuns em nomes de arquivos .tgz e repos-proxy)
  static final _generalRegex = RegExp(r'^[a-zA-Z0-9\-\.]+$');

  // Regex para caminhos de pacotes (aceita @ e / para escopos)
  static final _packageRegex = RegExp(r'^[a-zA-Z0-9\-\.\@\/]+$');

  static void validateGenericInput(String input) {
    if (!_generalRegex.hasMatch(input)) {
      throw SecurityException('Invalid characters in: $input');
    }
  }

  static void validatePackagePath(String path) {
    if (!_packageRegex.hasMatch(path)) {
      throw SecurityException('Invalid package path: $path');
    }
  }
}
