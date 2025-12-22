import 'dart:convert';
import 'package:sambura_core/application/usecase/generate_api_key_usecase.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:sambura_core/domain/repositories/api_key_repository.dart';
import 'package:sambura_core/domain/entities/account_entity.dart';

class ApiKeyController {
  final GenerateApiKeyUsecase _generateApiKeyUsecase;
  final ApiKeyRepository _keyRepo;

  ApiKeyController(this._generateApiKeyUsecase, this._keyRepo);

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
    try {
      final user = request.context['user'] as AccountEntity;
      final payload = jsonDecode(await request.readAsString());

      final String? keyName = payload['name'];
      if (keyName == null || keyName.isEmpty) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Dê um nome pra essa chave, cria!'}),
        );
      }

      final result = await _generateApiKeyUsecase.execute(
        accountId: user.id!,
        keyName: keyName,
      );

      return Response.ok(
        jsonEncode({
          'message':
              'Chave forjada com sucesso! Guarda bem, ela não aparece de novo.',
          'name': result.name,
          'api_key': result.plainKey,
        }),
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Erro ao gerar a chave: $e'}),
      );
    }
  }

  Future<Response> _list(Request request) async {
    final user = request.context['user'] as AccountEntity;
    final keys = await _keyRepo.findAllByAccount(user.id!);

    final response = keys
        .map(
          (k) => {
            'id': k.id,
            'name': k.name,
            'prefix': k.prefix,
            'last_used_at': k.lastUsedAt?.toIso8601String(),
            'created_at': k.expiresAt?.toIso8601String(),
          },
        )
        .toList();

    return Response.ok(jsonEncode(response));
  }

  Future<Response> _delete(Request request, String id) async {
    final keyId = int.tryParse(id);
    if (keyId == null) return Response.badRequest();

    await _keyRepo.delete(keyId);
    return Response.ok(
      jsonEncode({'message': 'Chave incinerada com sucesso!'}),
    );
  }
}
