import 'package:redis/redis.dart';
import 'package:logging/logging.dart';
import 'package:sambura_core/config/logger.dart';

class RedisService {
  final String host;
  final int port;
  final Logger _log = LoggerConfig.getLogger('RedisService');
  late Command _command;
  bool _isConnected = false;

  RedisService({required this.host, required this.port});

  Future<void> connect() async {
    try {
      final conn = RedisConnection();
      _command = await conn.connect(host, port);
      _isConnected = true;
      _log.info('✅ Conectado ao Redis em $host:$port');
    } catch (e) {
      _log.severe('🔥 Erro ao conectar no Redis: $e');
      _isConnected = false;
    }
  }

  Future<void> set(String key, String value, {int? expirySeconds}) async {
    if (!_isConnected) return;
    await _command.send_object(['SET', key, value]);
    if (expirySeconds != null) {
      await _command.send_object(['EXPIRE', key, expirySeconds]);
    }
  }

  Future<String?> get(String key) async {
    if (!_isConnected) return null;
    return await _command.get(key);
  }
}
