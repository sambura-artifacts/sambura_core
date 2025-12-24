import 'package:logging/logging.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/domain/entities/account_entity.dart';
import 'package:sambura_core/domain/repositories/account_repository.dart';
import 'package:sambura_core/infrastructure/database/postgres_connector.dart';

class PostgresAccountRepository implements AccountRepository {
  final PostgresConnector _connector;
  final Logger _log = LoggerConfig.getLogger('PostgresAccountRepository');

  PostgresAccountRepository(this._connector);

  @override
  Future<void> create(AccountEntity account) async {
    const sql = '''
      INSERT INTO accounts (external_id, username, password_hash, email, role)
      VALUES (@externalId, @username, @password, @email, @role)
    ''';

    try {
      await _connector.query(sql, {
        'externalId': account.externalId.value,
        'username': account.username.value,
        'password': account.password.value,
        'email': account.email.value,
        'role': account.role.value,
      });
      _log.info('✅ Usuário registrado: ${account.username}');
    } catch (e) {
      _log.severe('🔥 Erro ao criar conta no Postgres: $e');
      rethrow;
    }
  }

  @override
  Future<AccountEntity?> findByUsername(String username) async {
    const sql = 'SELECT * FROM accounts WHERE username = @username';

    final result = await _connector.query(sql, {'username': username});

    if (result.isEmpty) return null;

    final row = result.first.toColumnMap();

    return _mapToEntity(row);
  }

  @override
  Future<AccountEntity?> findById(int id) async {
    const sql = 'SELECT * FROM accounts WHERE id = @id';

    final result = await _connector.query(sql, {'id': id});

    if (result.isEmpty) return null;

    final row = result.first.toColumnMap();

    return _mapToEntity(row);
  }

  AccountEntity _mapToEntity(Map<String, dynamic> row) {
    return AccountEntity.restore(
      id: row['id'],
      externalId: row['external_id'],
      username: row['username'],
      password: row['password_hash'],
      email: row['email'],
      role: row['role'],
      createdAt: row['created_at'],
    );
  }

  @override
  Future<AccountEntity?> findByExternalId(String externalId) async {
    const sql = 'SELECT * FROM accounts WHERE external_id = @externalId';

    final result = await _connector.query(sql, {'externalId': externalId});

    if (result.isEmpty) return null;

    final row = result.first.toColumnMap();

    return _mapToEntity(row);
  }
}
