import 'dart:convert';

import 'package:sambura_core/domain/barrel.dart';

class NamespacePresenter {
  static Map<String, dynamic> _render(
    NamespaceEntity namespace,
    String baseUrl,
  ) {
    return {
      ...namespace.toMap(),
      '_links': {
        'self': '$baseUrl/admin/namespace/${namespace.name}',
        'resolve': '$baseUrl/${namespace.name}/<package>/<version>',
      },
    };
  }

  /// Transforma a entidade em um formato amigável para a API (JSON)

  static Map<String, dynamic> toJson(
    NamespaceEntity namespace,
    String baseUrl,
  ) {
    return {
      'id': namespace.id,
      'name': namespace.name,
      'type': namespace.escope,
      'isPublic': namespace.isPublic,
      'createdAt': namespace.createdAt?.toIso8601String(),
      '_links': {
        'self': '$baseUrl/admin/namespace/${namespace.name}',

        'packages': '$baseUrl/${namespace.name}/${namespace.escope}/packages',
      },
    };
  }

  static String listToJson({
    required List<NamespaceEntity> items,
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
          'next': '$baseUrl/admin/namespace?limit=$limit&offset=$nextOffset',
          'prev': offset > 0
              ? '$baseUrl/admin/namespace?limit=$limit&offset=$prevOffset'
              : null,
        },
      },
      'items': items.map((namespace) => _render(namespace, baseUrl)).toList(),
    });
  }

  static String entityToJson(NamespaceEntity namespace, String baseUrl) {
    return jsonEncode(_render(namespace, baseUrl));
  }
}
