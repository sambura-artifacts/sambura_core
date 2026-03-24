import 'package:equatable/equatable.dart';

/// Value Object representando uma API Key.
/// Garante que a chave seja válida e imutável.
class ApiKeyValue extends Equatable {
  final String value;
  final String prefix;

  const ApiKeyValue._({required this.value, required this.prefix});

  /// Cria uma ApiKeyValue validada.
  ///
  /// Formato esperado: "sb_live_[base64]" ou "sb_test_[base64]"
  factory ApiKeyValue.create(String value) {
    if (value.isEmpty) {
      throw ArgumentError('API Key cannot be empty');
    }

    // Validação do formato da chave
    if (!value.startsWith('sb_')) {
      throw ArgumentError('API Key must start with "sb_"');
    }

    final parts = value.split('_');
    if (parts.length < 3) {
      throw ArgumentError('Invalid API Key format');
    }

    final prefix = '${parts[0]}_${parts[1]}_';

    return ApiKeyValue._(value: value, prefix: prefix);
  }

  /// Cria sem validação
  const ApiKeyValue.unsafe({required this.value, required this.prefix});

  /// Retorna true se é uma chave de produção
  bool get isLive => prefix.contains('live');

  /// Retorna true se é uma chave de teste
  bool get isTest => prefix.contains('test');

  /// Mascara a chave para exibição (mostra apenas prefixo + últimos 4 chars)
  String get masked {
    if (value.length <= 12) return value;
    return '$prefix...${value.substring(value.length - 4)}';
  }

  @override
  String toString() => masked;

  /// Retorna o valor completo (use com cuidado!)
  String get plainValue => value;

  @override
  List<Object?> get props => [value];
}
