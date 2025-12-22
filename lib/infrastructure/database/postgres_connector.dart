import 'package:logging/logging.dart';
import 'package:postgres/postgres.dart';
import 'package:sambura_core/config/logger.dart';
import 'dart:async';

class PostgresConnector {
  final String host;
  final int port;
  final String user;
  final String password;
  final String database;
  final Logger _log = LoggerConfig.getLogger('PostgresConnector');

  Connection? _connection;

  PostgresConnector(
    this.host,
    this.port,
    this.user,
    this.password,
    this.database,
  );

  Connection get connection {
    if (_connection == null) throw Exception("Conexão não iniciada, cria!");
    return _connection!;
  }

  Future<void> connect() async {
    if (_connection != null && _connection!.isOpen) return;

    try {
      _log.info('Conectando ao Postgres: $host:$port/$database');
      _connection = await Connection.open(
        Endpoint(
          host: host,
          port: port,
          database: database,
          username: user,
          password: password,
        ),
        settings: const ConnectionSettings(
          sslMode: SslMode.disable, // For dev mode
          timeZone: 'UTC',
        ),
      );
      _log.info('Postgres conectado com sucesso');
    } catch (e, stackTrace) {
      _log.severe('Erro ao conectar no Postgres', e, stackTrace);
      rethrow;
    }
  }

  // Ajusta o retorno para Future<Result> (sem o ?)
  Future<Result> query(
    String sql,
    Map<String, dynamic> substitutionValues,
  ) async {
    // 1. Garante que tá conectado antes de qualquer coisa
    await connect();

    try {
      // 2. Usa o getter 'db' que já lança exceção se estiver nulo
      // Assim o compilador sabe que o retorno de execute será um Result real
      return await db.execute(Sql.named(sql), parameters: substitutionValues);
    } catch (e, stackTrace) {
      _log.severe('Erro ao executar query', e, stackTrace);
      _log.fine('SQL: $sql');
      _log.fine('Params: $substitutionValues');
      rethrow;
    }
  }

  Future<StatementResul> execute(
    String sql,
    Map<String, String> map, {
    Map<String, dynamic>? parameters,
  }) async {
    await connect();
    final result = await _connection!.execute(
      Sql.named(sql),
      parameters: parameters,
    );
    return StatementResul(result.affectedRows);
  }

  Future<void> disconnect() async {
    await _connection?.close();
    _connection = null;
  }

  Connection get db {
    if (_connection == null || !_connection!.isOpen) {
      throw Exception('Postgres não inicializado. Chame connect() primeiro.');
    }
    return _connection!;
  }
}

class StatementResul {
  final int affectedRows;
  StatementResul(this.affectedRows);
}
