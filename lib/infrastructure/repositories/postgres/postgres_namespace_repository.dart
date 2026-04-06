import 'package:logging/logging.dart';

import 'package:sambura_core/config/barrel.dart';
import 'package:sambura_core/domain/barrel.dart';
import 'package:sambura_core/infrastructure/barrel.dart';

class PostgresNamespaceRepository implements NamespaceRepository {
  final PostgresConnector _db;
  final Logger _log = LoggerConfig.getLogger('PostgresNamespaceRepository');

  PostgresNamespaceRepository(this._db);

  @override
  Future<List<NamespaceEntity>> list({int limit = 10, int offset = 0}) async {
    try {
      final result = await _db.query(
        'SELECT * FROM namespaces ORDER BY created_at DESC LIMIT @limit OFFSET @offset',
        substitutionValues: {'limit': limit, 'offset': offset},
      );
      return result
          .map((row) => NamespaceEntity.fromMap(row.toColumnMap()))
          .toList();
    } catch (e, stackTrace) {
      _log.severe('Erro na listagem de repositórios', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<NamespaceEntity?> getByName(String name) async {
    try {
      final result = await _db.query(
        '''
        SELECT 
          n.id, 
          pm.name as package_manager, 
          n.name, 
          n.escope, 
          n.is_public, 
          n.remote_url, 
          n.created_at 
        FROM 
          namespaces n
          JOIN package_manager pm ON n.package_manager_id = pm.id
        WHERE 
          n.name = @name
        ''',
        substitutionValues: {'name': name},
      );
      if (result.isEmpty) return null;
      return NamespaceEntity.fromMap(result.first.toColumnMap());
    } catch (e, stackTrace) {
      _log.severe('Erro ao buscar repositório por nome: $name', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<NamespaceEntity>> listByNamespace(String escope) async {
    try {
      final result = await _db.query(
        'SELECT * FROM namespaces WHERE escope = @escope',
        substitutionValues: {'escope': escope},
      );
      return result
          .map((row) => NamespaceEntity.fromMap(row.toColumnMap()))
          .toList();
    } catch (e, stackTrace) {
      _log.severe('Erro ao listar por namespace: $escope', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<NamespaceEntity> save(NamespaceEntity repository) async {
    _log.fine(
      'Salvando: name=${repository.name}, escope=${repository.escope}, public=${repository.isPublic}',
    );

    try {
      // Garante que o SQL e os parâmetros estão batendo certinho
      final sql = '''
        INSERT INTO namespaces (package_manager, name, escope, is_public) 
        VALUES (@package_manager, @name, @namespace, @is_public) 
        ON CONFLICT (name) DO UPDATE SET 
          escope = EXCLUDED.escope, 
          is_public = EXCLUDED.is_public 
        RETURNING id, package_manager, name, escope, is_public, created_at
      ''';

      final result = await _db.query(
        sql,
        substitutionValues: {
          'package_manager': repository.packageManager,
          'name': repository.name,
          'escope': repository.escope,
          'is_public': repository.isPublic,
        },
      );

      if (result.isEmpty) throw Exception("Linha vazia no retorno");

      final row = result.first.toColumnMap();
      final saved = NamespaceEntity.fromMap(row);
      _log.info('Repositório salvo: ID=${saved.id}, name=${saved.name}');
      return saved;
    } catch (e, stackTrace) {
      _log.severe('Erro ao salvar repositório', e, stackTrace);
      rethrow;
    }
  }
}
