import 'dart:convert';
import 'package:dart_amqp/dart_amqp.dart';
import 'package:sambura_core/domain/services/queue_service.dart';

class RabbitMQQueueService implements QueueService {
  final String host;
  final int port;
  final String user;
  final String password;
  final String vhost;

  Client? _client;
  Channel? _channel;

  RabbitMQQueueService({
    required this.host,
    required this.port,
    required this.user,
    required this.password,
    this.vhost = '/',
  });

  /// Garante a conexão e o canal com o broker
  Future<void> _ensureConnection() async {
    if (_client != null && _channel != null) return;

    try {
      final settings = ConnectionSettings(
        host: host,
        port: port,
        authProvider: PlainAuthenticator(user, password),
        virtualHost: vhost,
      );

      _client = Client(settings: settings);
      _channel = await _client!.channel();

      print('🐰 [RabbitMQ] Conectado com sucesso em $host:$port');
    } catch (e) {
      print('❌ [RabbitMQ] Erro de conexão: $e');
      rethrow;
    }
  }

  @override
  Future<void> publish(String queueName, Map<String, dynamic> message) async {
    try {
      await _ensureConnection();

      // durable: true -> a fila sobrevive se o broker reiniciar
      final queue = await _channel!.queue(queueName, durable: true);

      // Converte o mapa pra JSON e despacha
      final payload = jsonEncode(message);
      queue.publish(payload);

      print('🚀 [Queue] Mensagem enviada para "$queueName"');
    } catch (e) {
      print('❌ [Queue] Falha ao publicar mensagem: $e');
      // Aqui tu poderia implementar um retry ou logar num Sentry da vida
      rethrow;
    }
  }

  /// Fecha a conexão quando o app for desligado
  Future<void> dispose() async {
    await _client?.close();
    _client = null;
    _channel = null;
  }
}
