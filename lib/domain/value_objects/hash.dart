import 'package:equatable/equatable.dart';

/// Value Object representando um hash SHA-256.
/// Garante que o hash seja válido e imutável.
class Hash extends Equatable {
  final String value;

  const Hash._(this.value);

  /// Cria um Hash validado.
  ///
  /// Deve ser uma string hexadecimal de 64 caracteres (SHA-256)
  factory Hash.create(String value) {
    if (value.isEmpty) {
      throw ArgumentError('Hash cannot be empty');
    }

    // SHA-256 tem 64 caracteres hexadecimais
    final sha256Pattern = RegExp(r'^[a-fA-F0-9]{64}$');
    if (!sha256Pattern.hasMatch(value)) {
      throw ArgumentError(
        'Invalid SHA-256 hash format. Expected 64 hex characters, got: ${value.length}',
      );
    }

    return Hash._(value.toLowerCase());
  }

  /// Cria sem validação (para reconstrução do banco)
  const Hash.unsafe(this.value);

  /// Retorna os primeiros N caracteres do hash
  String prefix([int length = 12]) {
    return value.substring(0, length.clamp(0, value.length));
  }

  /// Verifica se este hash corresponde a outro
  bool matches(Hash other) => value == other.value;

  @override
  String toString() => value;

  @override
  List<Object?> get props => [value];
}
