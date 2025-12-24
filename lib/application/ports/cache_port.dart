/// Port (Interface) para serviço de cache.
///
/// Define o contrato para operações de cache distribuído.
/// Pode ser implementado com Redis, Memcached, ou cache em memória.
abstract class CachePort {
  /// Armazena um valor no cache com tempo de expiração.
  ///
  /// [key] - Chave única
  /// [value] - Valor a ser armazenado
  /// [ttl] - Time to live em segundos (opcional)
  Future<void> set(String key, String value, {Duration? ttl});

  /// Recupera um valor do cache.
  ///
  /// [key] - Chave única
  /// Returns: Valor armazenado ou null se não existir/expirado
  Future<String?> get(String key);

  /// Remove um valor do cache.
  ///
  /// [key] - Chave única
  Future<void> delete(String key);

  /// Verifica se uma chave existe no cache.
  ///
  /// [key] - Chave única
  /// Returns: true se existe e não expirou
  Future<bool> exists(String key);

  /// Invalida múltiplas chaves que correspondem a um padrão.
  ///
  /// [pattern] - Padrão glob (ex: "user:*")
  Future<void> invalidatePattern(String pattern);

  /// Incrementa um contador atomicamente.
  ///
  /// [key] - Chave do contador
  /// [delta] - Valor a incrementar (padrão: 1)
  /// Returns: Novo valor após incremento
  Future<int> increment(String key, {int delta = 1});

  /// Define tempo de expiração para uma chave existente.
  ///
  /// [key] - Chave única
  /// [ttl] - Time to live
  Future<void> expire(String key, Duration ttl);
}
