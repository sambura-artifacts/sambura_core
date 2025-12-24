import 'package:sambura_core/domain/exceptions/domain_exception.dart';

class PackageName {
  final String value;

  PackageName(String val) : value = val.trim() {
    _validate(value);
  }

  void _validate(String val) {
    if (val.isEmpty) {
      throw PackageNameException('O nome do pacote não pode estar vazio.');
    }

    if (val.length > 214) {
      throw PackageNameException(
        'O nome do pacote é muito longo (máx 214 chars).',
      );
    }

    final regex = RegExp(
      r'^(?:@[a-z0-9-*~][a-z0-9-*._~]*/)?[a-z0-9-~][a-z0-9-._~]*$',
    );

    if (!regex.hasMatch(val)) {
      throw PackageNameException(
        'Nome de pacote inválido: "$val". Siga o padrão do NPM (ex: @scope/nome).',
      );
    }

    final reserved = ['node_modules', 'favicon.ico'];
    if (reserved.contains(val.toLowerCase())) {
      throw PackageNameException('O nome "$val" é reservado pelo sistema.');
    }
  }

  bool get isScoped => value.startsWith('@');

  String get scope => isScoped ? value.split('/').first : '';

  String get nameWithoutScope => isScoped ? value.split('/').last : value;

  @override
  String toString() => value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PackageName && value == other.value;

  @override
  int get hashCode => value.hashCode;
}
