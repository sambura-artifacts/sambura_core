import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/application/usecase/api_key/generate_api_key_usecase.dart';
import 'package:sambura_core/application/usecase/api_key/list_api_keys_usecase.dart';
import 'package:sambura_core/application/usecase/api_key/revoke_api_key_usecase.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:sambura_core/domain/entities/account_entity.dart';
import 'package:sambura_core/infrastructure/api/presenter/admin/api_key_presenter.dart';

class ApiKeyController {
  final GenerateApiKeyUsecase _generateApiKeyUsecase;
  final ListApiKeysUsecase _listApiKeysUsecase;
  final RevokeApiKeyUsecase _revokeApiKeyUsecase;
  final Logger _log = LoggerConfig.getLogger('ApiKeyController');

  ApiKeyController(
    this._generateApiKeyUsecase,
    this._listApiKeysUsecase,
    this._revokeApiKeyUsecase,
  );

  // Define as rotas do controller
  Router get router {
    final router = Router();

    // POST /admin/api-keys -> Cria uma chave nova
    router.post('/', _create);

    // GET /admin/api-keys -> Lista as chaves do usuário logado
    router.get('/', _list);

    // DELETE /admin/api-keys/<id> -> Revoga uma chave
    router.delete('/<id>', _delete);

    return router;
  }

  Future<Response> _create(Request request) async {
    final requestId = DateTime.now().millisecondsSinceEpoch.toString();
    _log.info(
      '[REQ:$requestId] POST /admin/api-keys - Solicitação de criação de API key',
    );

    try {
      if (request.context['user'] == null) {
        return ApiKeyPresenter.unauthorized('/api/v1/admin/api-keys');
      }
      final user = request.context['user'] as AccountEntity;
      final payload = jsonDecode(await request.readAsString());

      final String? keyName = payload['name'];
      if (keyName == null || keyName.isEmpty) {
        _log.warning('[REQ:$requestId] ✗ Tentativa de criar API key sem nome');
        return ApiKeyPresenter.missingKeyName('/api/v1/admin/api-keys');
      }

      _log.info(
        '[REQ:$requestId] Gerando API key para usuário: ${user.username}, nome da chave: $keyName',
      );

      final result = await _generateApiKeyUsecase.execute(
        accountId: user.id!,
        keyName: keyName,
      );

      _log.info(
        '[REQ:$requestId] ✓ API key criada com sucesso: ${result.name}, prefix: ${result.prefix}',
      );
      return ApiKeyPresenter.created(result);
    } catch (e, stack) {
      _log.severe('[REQ:$requestId] ✗ Erro ao gerar API key', e, stack);
      return ApiKeyPresenter.internalServerError(
        'Erro ao gerar a chave',
        '/api/v1/admin/api-keys',
        error: e,
        stack: stack,
      );
    }
  }

  Future<Response> _list(Request request) async {
    final requestId = DateTime.now().millisecondsSinceEpoch.toString();

    if (request.context['user'] == null) {
      return ApiKeyPresenter.unauthorized('/api/v1/admin/api-keys');
    }

    final user = request.context['user'] as AccountEntity;

    _log.info(
      '[REQ:$requestId] GET /admin/api-keys - Listando API keys do usuário: ${user.username}',
    );

    try {
      final keys = await _listApiKeysUsecase.execute(accountId: user.id!);

      _log.info(
        '[REQ:$requestId] ✓ Encontradas ${keys.length} API keys para o usuário',
      );

      return ApiKeyPresenter.list(keys);
    } catch (e, stack) {
      _log.severe('[REQ:$requestId] ✗ Erro ao listar API keys', e, stack);
      return ApiKeyPresenter.internalServerError(
        'Erro ao listar chaves',
        '/api/v1/admin/api-keys',
        error: e,
        stack: stack,
      );
    }
  }

  Future<Response> _delete(Request request, String id) async {
    if (request.context['user'] == null) {
      return ApiKeyPresenter.unauthorized('/api/v1/admin/api-keys');
    }
    final user = request.context['user'] as AccountEntity;

    final requestId = DateTime.now().millisecondsSinceEpoch.toString();

    _log.info(
      '[REQ:$requestId] DELETE /admin/api-keys/$id - Solicitação de revogação',
    );

    final keyId = int.tryParse(id);
    if (keyId == null) {
      _log.warning('[REQ:$requestId] ✗ ID inválido fornecido: $id');
      return ApiKeyPresenter.invalidKeyId(id, '/api/v1/admin/api-keys/$id');
    }

    try {
      await _revokeApiKeyUsecase.execute(
        key: id,
        requestUserId: user.externalIdValue,
      );
      _log.info('[REQ:$requestId] ✓ API key revogada com sucesso: ID=$keyId');
      return ApiKeyPresenter.revoked(keyId);
    } catch (e, stack) {
      _log.severe(
        '[REQ:$requestId] ✗ Erro ao revogar API key: ID=$keyId',
        e,
        stack,
      );
      return ApiKeyPresenter.internalServerError(
        'Erro ao revogar chave',
        '/api/v1/admin/api-keys/$id',
        error: e,
        stack: stack,
      );
    }
  }
}
