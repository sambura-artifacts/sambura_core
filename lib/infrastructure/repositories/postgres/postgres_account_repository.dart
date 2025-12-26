import 'package:logging/logging.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/domain/entities/account_entity.dart';
import 'package:sambura_core/domain/repositories/account_repository.dart';
import 'package:sambura_core/infrastructure/database/postgres_connector.dart';
import 'package:sambura_core/infrastructure/mappers/account_mapper.dart';

class PostgresAccountRepository implements AccountRepository {
  final PostgresConnector _connector;
  final Logger _log = LoggerConfig.getLogger('PostgresAccountRepository');

  PostgresAccountRepository(this._connector);

  @override
  Future<void> create(AccountEntity account) async {
    const sql = '''
      INSERT INTO accounts (external_id, username, password, email, role)
      VALUES (@externalId, @username, @password, @email, @role)
    ''';

    try {
      await _connector.query(
        sql,
        substitutionValues: {
          'externalId': account.externalId.value,
          'username': account.username.value,
          'password': account.password!.value,
          'email': account.email.value,
          'role': account.role.value,
        },
      );
      _log.info('✅ Usuário registrado: ${account.username}');
    } catch (e) {
      _log.severe('🔥 Erro ao criar conta no Postgres: $e');
      rethrow;
    }
  }

  @override
  Future<AccountEntity?> findByUsername(String username) async {
    const sql = 'SELECT * FROM accounts WHERE username = @username';

    final result = await _connector.query(
      sql,
      substitutionValues: {'username': username},
    );

    if (result.isEmpty) return null;

    final row = result.first.toColumnMap();

    return _mapToEntity(row);
  }

  @override
  Future<AccountEntity?> findById(int id) async {
    const sql = 'SELECT * FROM accounts WHERE id = @id';

    final result = await _connector.query(sql, substitutionValues: {'id': id});

    if (result.isEmpty) return null;

    final row = result.first.toColumnMap();

    return _mapToEntity(row);
  }

  AccountEntity _mapToEntity(Map<String, dynamic> row) {
    return AccountEntity.restore(
      id: row['id'],
      externalId: row['external_id'],
      username: row['username'],
      password: row['password'],
      email: row['email'],
      role: row['role'],
      createdAt: row['created_at'],
    );
  }

  @override
  Future<AccountEntity?> findByExternalId(String externalId) async {
    try {
      // Certifique-se de que a coluna se chama external_id e é do tipo UUID ou VARCHAR
      final result = await _connector.query(
        'SELECT * FROM accounts WHERE external_id = @externalId',
        substitutionValues: {'externalId': externalId},
      );

      if (result.isEmpty) {
        _log.warning('👤 Usuário não encontrado para o UUID: $externalId');
        return null;
      }

      // Use o seu Mapper ou o construtor manual
      return AccountMapper.fromMap(result.first.toColumnMap());
    } catch (e, stack) {
      _log.severe('💥 Erro ao buscar usuário por UUID: $externalId', e, stack);
      return null;
    }
  }

  @override
  Future<bool> existsByRole(String role) async {
    const sql = 'select 1 from accounts WHERE role = @role;';

    final result = await _connector.query(
      sql,
      substitutionValues: {'role': role},
    );

    if (result.isEmpty) return false;

    return true;
  }
}
