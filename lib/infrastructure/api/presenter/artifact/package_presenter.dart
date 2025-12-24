import 'dart:convert';

class PackagePresenter {
  static String renderList(
    List<dynamic> packages,
    String repoName,
    String baseUrl,
    int limit,
    int offset,
  ) {
    return jsonEncode({
      'metadata': {
        'repository': repoName,
        'count': packages.length,
        'limit': limit,
        'offset': offset,
        'next':
            '$baseUrl/admin/repositories/$repoName/packages?limit=$limit&offset=${offset + limit}',
      },
      'items': packages.map((p) => renderSingle(p, repoName, baseUrl)).toList(),
    });
  }

  /// Transforma um único pacote no formato de saída
  static Map<String, dynamic> renderSingle(
    dynamic p,
    String repoName,
    String baseUrl,
  ) {
    return {
      'id': p.id,
      'name': p.name,
      'createdAt': p.createdAt?.toIso8601String(),
      '_links': {
        'self': '$baseUrl/admin/repositories/$repoName/packages/${p.name}',
        'versions': '$baseUrl/$repoName/${p.name}',
      },
    };
  }
}
