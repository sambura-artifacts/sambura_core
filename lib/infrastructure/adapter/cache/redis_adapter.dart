import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:redis/redis.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/application/ports/barrel.dart';

/// Adapter para Redis implementando ICachePort.
///
/// Segue o padrão Hexagonal Architecture (Ports & Adapters).
class RedisAdapter implements CachePort {
  final String _host;
  final int _port;
  final Logger _log = LoggerConfig.getLogger('RedisAdapter');

  Command? _command;
  bool _isConnected = false;

  RedisAdapter({required String host, required int port})
    : _host = host,
      _port = port;

  /// Conecta ao Redis.
  Future<void> connect() async {
    try {
      _log.info('🔌 Connecting to Redis at $_host:$_port');

      final conn = RedisConnection();
      _command = await conn.connect(_host, _port);

      _isConnected = true;

      _log.info('✅ Redis connected successfully');
    } catch (e, stack) {
      _log.severe('❌ Failed to connect to Redis: $e', e, stack);
      _isConnected = false;
      rethrow;
    }
  }

  Future<void> _ensureConnected() async {
    // Se o comando sumiu ou a flag diz que desconectou, tentamos recuperar
    if (_command == null || !_isConnected) {
      _log.info(
        '🔄 Redis connection lost or not initialized. Attempting to reconnect...',
      );

      try {
        // Importante: Chame o seu método de conexão original aqui
        // Supondo que você tenha as configs de host/porta guardadas
        await connect();

        if (_command == null) {
          throw Exception('Could not re-establish Redis connection');
        }

        _log.info('✅ Redis reconnected successfully.');
      } catch (e) {
        _log.severe('❌ Failed to auto-reconnect to Redis: $e');
        // Aqui você pode decidir se joga a Exception ou se deixa o
        // UseCase seguir (o que resultará em Cache Miss, mas não mata o app)
        throw Exception('Redis is unavailable');
      }
    }
  }

  @override
  Future<void> set(String key, String value, {Duration? ttl}) async {
    await _ensureConnected();

    try {
      if (ttl != null) {
        await _command!.send_object(['SETEX', key, ttl.inSeconds, value]);
      } else {
        await _command!.send_object(['SET', key, value]);
      }

      _log.fine('✅ Set key: $key');
    } catch (e) {
      _log.warning('⚠️  Failed to set key $key: $e');
      rethrow;
    }
  }

  @override
  Future<String?> get(String key) async {
    await _ensureConnected();

    try {
      final value = await _command!.send_object(['GET', key]);

      if (value == null) {
        _log.fine('🔍 Key not found: $key');
        return null;
      }

      _log.fine('✅ Got key: $key');
      return value.toString();
    } catch (e) {
      _log.warning('⚠️  Failed to get key $key: $e');
      return null;
    }
  }

  @override
  Future<void> delete(String key) async {
    await _ensureConnected();

    try {
      await _command!.send_object(['DEL', key]);
      _log.fine('🗑️  Deleted key: $key');
    } catch (e) {
      _log.warning('⚠️  Failed to delete key $key: $e');
      rethrow;
    }
  }

  @override
  Future<bool> exists(String key) async {
    await _ensureConnected();

    try {
      final result = await _command!.send_object(['EXISTS', key]);
      return result == 1;
    } catch (e) {
      _log.warning('⚠️  Failed to check existence of key $key: $e');
      return false;
    }
  }

  @override
  Future<void> invalidatePattern(String pattern) async {
    await _ensureConnected();

    try {
      // SCAN para encontrar chaves que correspondem ao padrão
      final keys = await _command!.send_object(['KEYS', pattern]);

      if (keys is List && keys.isNotEmpty) {
        await _command!.send_object(['DEL', ...keys]);
        _log.info('🗑️  Invalidated ${keys.length} keys matching: $pattern');
      }
    } catch (e) {
      _log.warning('⚠️  Failed to invalidate pattern $pattern: $e');
      rethrow;
    }
  }

  @override
  Future<int> increment(String key, {int delta = 1}) async {
    await _ensureConnected();

    try {
      final result = await _command!.send_object(['INCRBY', key, delta]);
      _log.fine('➕ Incremented key $key by $delta: $result');
      return result as int;
    } catch (e) {
      _log.warning('⚠️  Failed to increment key $key: $e');
      rethrow;
    }
  }

  @override
  Future<void> expire(String key, Duration ttl) async {
    await _ensureConnected();

    try {
      await _command!.send_object(['EXPIRE', key, ttl.inSeconds]);
      _log.fine('⏰ Set expiration for key $key: ${ttl.inSeconds}s');
    } catch (e) {
      _log.warning('⚠️  Failed to set expiration for key $key: $e');
      rethrow;
    }
  }

  /// Desconecta do Redis.
  Future<void> disconnect() async {
    if (_isConnected) {
      _log.info('👋 Disconnecting from Redis');
      _isConnected = false;
      _command = null;
    }
  }

  @override
  Future<bool> isHealthy() async {
    try {
      final response = await _command!.send_object(['PING']);
      return response == 'PONG';
    } catch (e) {
      _log.severe('❌ Erro de saúde no Redis: $e');
      return false;
    }
  }

  @override
  Future<bool> acquireLock(
    String key, {
    Duration duration = const Duration(seconds: 30),
  }) async {
    try {
      final response = await _command!.send_object([
        "SET",
        key,
        "locked",
        "EX",
        duration.inSeconds.toString(),
        "NX",
      ]);

      return response == "OK";
    } catch (e) {
      _log.warning('⚠️ Erro ao comunicar com Redis para lock: $e');
      return false;
    }
  }

  @override
  Future<void> releaseLock(String key) async {
    try {
      await _command!.send_object(["DEL", key]);
    } catch (e) {
      _log.warning('⚠️ Erro ao liberar lock: $e');
    }
  }

  @override
  Future<Uint8List?> getBinary(String key) async {
    try {
      await _ensureConnected();

      // Use await direto em vez de .then() para garantir que o catch capture erros do send_object
      final value = await _command!.send_object(['GET', key]);

      if (value == null) {
        _log.fine('🔍 Binary key not found: $key');
        return null;
      }

      _log.fine('✅ Got binary key: $key');
      return value
          as Uint8List; // Garante o cast correto para o tipo de retorno
    } catch (e) {
      _log.warning('⚠️ Failed to get binary key $key: $e');
      _command = null; // Se falhou o GET por socket, limpa para reconectar
      return null;
    }
  }

  @override
  Future<void> setBinary(String key, List<int> value, {Duration? ttl}) async {
    try {
      await _ensureConnected();

      if (ttl != null) {
        // Usando a sintaxe moderna 'SET key value EX seconds'
        await _command!.send_object([
          'SET',
          key,
          value,
          'EX',
          ttl.inSeconds.toString(),
        ]);
      } else {
        await _command!.send_object(['SET', key, value]);
      }

      _log.fine('💾 Key saved to Redis: $key (${value.length} bytes)');
    } catch (e) {
      _log.warning('⚠️ Failed to set binary key $key: $e');
      _command = null; // Força reconexão no próximo hit
      // Mantemos o silêncio aqui para o UseCase não crashar o download
    }
  }
}
