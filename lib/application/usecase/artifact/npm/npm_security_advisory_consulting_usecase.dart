import 'package:logging/logging.dart';

import 'package:sambura_core/application/barrel.dart';
import 'package:sambura_core/config/barrel.dart';

class NpmSecurityAdvisoryConsultingUsecase {
  final HttpClientPort _client;
  final Logger _log = LoggerConfig.getLogger(
    'NpmSecurityAdvisoryConsultingUsecase',
  );
  NpmSecurityAdvisoryConsultingUsecase(this._client);
  Future<List<int>> execute(Map<String, String> headers, List<int> body) async {
    final response = await _client.post(
      Uri.parse('/-/npm/v1/security/advisories/bulk'),
      headers: {
        'Content-Type': 'application',
        'Content-Encoding': 'gzip',
        ...headers,
      },
      body: body,
    );

    if (response.statusCode != 200) {
      _log.warning(
        'Requisição rejeitada: HTTP Status Code ${response.statusCode}',
      );
    }

    _log.info('Tamanho da resposta: ${response.bodyBytes.length} bytes');

    return response.bodyBytes;
  }
}
