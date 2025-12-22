import 'package:redis/redis.dart';

class RedisConnector {
  final String host;
  final int port;

  Command? _command;
  RedisConnection? _connection;

  RedisConnector(this.host, this.port);

  Future<void> connect() async {
    if (_command != null) return;

    try {
      _connection = RedisConnection();
      _command = await _connection!.connect(host, port);
      print('⚡ Redis Conectado: $host:$port');
    } catch (e) {
      print('❌ Erro ao conectar no Redis: $e');
      rethrow;
    }
  }

  Future<void> set(String key, String value, {Duration? ttl}) async {
    await connect();
    await _command!.send_object(["SET", key, value]);
    if (ttl != null) {
      await _command!.send_object(["EXPIRE", key, ttl.inSeconds.toString()]);
    }
  }

  Future<String?> get(String key) async {
    await connect();
    final response = await _command!.send_object(["GET", key]);
    return response?.toString();
  }

  Future<void> delete(String key) async {
    await connect();
    await _command!.send_object(["DEL", key]);
  }

  Future<void> disconnect() async {
    _connection = null;
    _command = null;
  }

  Command get client {
    if (_command == null) {
      throw Exception('Redis não conectado. Chame connect() primeiro.');
    }
    return _command!;
  }
}
