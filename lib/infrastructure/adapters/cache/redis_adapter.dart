import 'package:logging/logging.dart';
import 'package:redis/redis.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/application/ports/cache_port.dart';

/// Adapter para Redis implementando ICachePort.
///
/// Segue o padrão Hexagonal Architecture (Ports & Adapters).
class RedisAdapter implements ICachePort {
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

  void _ensureConnected() {
    if (!_isConnected || _command == null) {
      throw Exception('Redis not connected. Call connect() first.');
    }
  }

  @override
  Future<void> set(String key, String value, {Duration? ttl}) async {
    _ensureConnected();

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
    _ensureConnected();

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
    _ensureConnected();

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
    _ensureConnected();

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
    _ensureConnected();

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
    _ensureConnected();

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
    _ensureConnected();

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
}
