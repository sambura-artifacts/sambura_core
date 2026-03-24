import 'package:sambura_core/domain/exceptions/exceptions.dart';

class PackageName {
  final String value;

  PackageName(String val) : value = val.trim() {
    _validate(value);
  }

  void _validate(String val) {
    if (val.isEmpty) {
      throw PackageNameException('O nome do pacote não pode estar vazio.');
    }

    if (val.length > 512) {
      // Aumentado para suportar Maven Group IDs longos
      throw PackageNameException(
        'O nome do pacote é muito longo (máx 512 chars).',
      );
    }

    // Regex universal básica (aceita @, /, -, ., :, _)
    final regex = RegExp(r'^[a-zA-Z0-9\-\._\@\/:]+$');

    if (!regex.hasMatch(val)) {
      throw PackageNameException(
        'Nome de pacote inválido: "$val". Use apenas caracteres permitidos.',
      );
    }
  }

  bool get isScoped => value.contains('/') || value.contains(':');

  String get scope {
    if (!isScoped) return '';
    if (value.contains('/')) {
      return value.split('/').first;
    }
    if (value.contains(':')) {
      return value.split(':').first;
    }
    return '';
  }

  String get nameWithoutScope {
    if (!isScoped) return value;
    if (value.contains('/')) {
      return value.split('/').last;
    }
    if (value.contains(':')) {
      return value.split(':').last;
    }
    return value;
  }

  @override
  String toString() => value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PackageName && value == other.value;

  @override
  int get hashCode => value.hashCode;
}
