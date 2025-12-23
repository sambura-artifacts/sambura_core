import 'package:equatable/equatable.dart';

/// Value Object representando o nome de um pacote.
/// Garante que o nome do pacote seja válido e imutável.
class PackageName extends Equatable {
  final String value;

  const PackageName._(this.value);

  /// Cria um PackageName validado.
  ///
  /// Regras:
  /// - Não pode ser vazio
  /// - Pode conter escopo (@scope/package)
  /// - Deve seguir convenções NPM
  factory PackageName.create(String value) {
    if (value.isEmpty) {
      throw ArgumentError('Package name cannot be empty');
    }

    // Validação básica de formato NPM
    final npmPattern = RegExp(
      r'^(@[a-z0-9-~][a-z0-9-._~]*/)?[a-z0-9-~][a-z0-9-._~]*$',
    );
    if (!npmPattern.hasMatch(value)) {
      throw ArgumentError('Invalid package name format: $value');
    }

    return PackageName._(value);
  }

  /// Cria sem validação (para reconstrução do banco)
  const PackageName.unsafe(this.value);

  /// Retorna true se o pacote tem escopo (@scope/name)
  bool get hasScope => value.startsWith('@');

  /// Retorna o escopo do pacote (ex: @sambura)
  String? get scope {
    if (!hasScope) return null;
    final parts = value.split('/');
    return parts.isNotEmpty ? parts[0] : null;
  }

  /// Retorna o nome sem escopo
  String get nameWithoutScope {
    if (!hasScope) return value;
    final parts = value.split('/');
    return parts.length > 1 ? parts[1] : value;
  }

  @override
  String toString() => value;

  @override
  List<Object?> get props => [value];
}
