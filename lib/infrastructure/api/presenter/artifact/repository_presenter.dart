import 'dart:convert';
import 'package:sambura_core/domain/entities/repository_entity.dart';

class RepositoryPresenter {
  static Map<String, dynamic> _render(RepositoryEntity repo, String baseUrl) {
    return {
      ...repo.toMap(),
      '_links': {
        'self': '$baseUrl/admin/repositories/${repo.name}',
        'resolve': '$baseUrl/${repo.name}/<package>/<version>',
      },
    };
  }

  /// Transforma a entidade em um formato amigável para a API (JSON)

  static Map<String, dynamic> toJson(RepositoryEntity repo, String baseUrl) {
    return {
      'id': repo.id,
      'name': repo.name,
      'type': repo.namespace,
      'isPublic': repo.isPublic,
      'createdAt': repo.createdAt?.toIso8601String(),
      '_links': {
        'self': '$baseUrl/admin/repositories/${repo.name}',

        'packages': '$baseUrl/${repo.name}/${repo.namespace}/packages',
      },
    };
  }

  static String listToJson({
    required List<RepositoryEntity> items,
    required String baseUrl,
    required int limit,
    required int offset,
  }) {
    final nextOffset = offset + limit;
    final prevOffset = offset - limit < 0 ? 0 : offset - limit;

    return jsonEncode({
      'metadata': {
        'count': items.length,
        'limit': limit,
        'offset': offset,
        'links': {
          'next': '$baseUrl/admin/repositories?limit=$limit&offset=$nextOffset',
          'prev': offset > 0
              ? '$baseUrl/admin/repositories?limit=$limit&offset=$prevOffset'
              : null,
        },
      },
      'items': items.map((repo) => _render(repo, baseUrl)).toList(),
    });
  }

  static String entityToJson(RepositoryEntity repo, String baseUrl) {
    return jsonEncode(_render(repo, baseUrl));
  }
}
