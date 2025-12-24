import 'package:sambura_core/domain/exceptions/domain_exception.dart';

class SemVer {
  final String value;

  SemVer(String val) : value = val.trim() {
    _validate(value);
  }

  void _validate(String val) {
    if (val.isEmpty) {
      throw SemVerException('A versão não pode estar vazia.');
    }

    // Regex Oficial SemVer 2.0.0
    // Suporta: 1.0.0, 1.0.0-alpha, 1.2.3-beta.1+build.123
    final regex = RegExp(
      r"^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][a-zA-Z0-9-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][a-zA-Z0-9-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$",
    );

    if (!regex.hasMatch(val)) {
      throw SemVerException(
        'Versão inválida: "$val". Use o padrão Semantic Versioning (ex: 1.0.0).',
      );
    }
  }

  // Helpers para comparação futura
  int get major => int.parse(value.split('.')[0]);
  int get minor => int.parse(value.split('.')[1]);
  int get patch => int.parse(value.split('.')[2].split('-')[0].split('+')[0]);

  @override
  String toString() => value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SemVer && value == other.value;

  @override
  int get hashCode => value.hashCode;
}
