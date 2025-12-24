import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:logging/logging.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/application/usecase/account/create_account_usecase.dart';
import 'package:sambura_core/application/usecase/auth/login_usecase.dart';

class AuthController {
  final CreateAccountUsecase _createAccountUsecase;
  final LoginUsecase _loginUsecase;
  final Logger _log = LoggerConfig.getLogger('AuthController');

  AuthController(this._createAccountUsecase, this._loginUsecase);

  // POST /auth/register
  Future<Response> register(Request request) async {
    final requestId = DateTime.now().millisecondsSinceEpoch.toString();
    _log.info(
      '[REQ:$requestId] POST /auth/register - Iniciando registro de usuário',
    );

    try {
      final body = jsonDecode(await request.readAsString());
      final username = body['username'];
      final email = body['email'];
      final role = body['role'] ?? 'developer';

      _log.info(
        '[REQ:$requestId] Registrando usuário: username=$username, email=$email, role=$role',
      );

      await _createAccountUsecase.execute(
        username: username,
        password: body['password'],
        email: email,
        role: role,
      );

      _log.info('[REQ:$requestId] ✓ Usuário registrado com sucesso: $username');
      return Response.ok(
        jsonEncode({'message': 'Usuário criado com sucesso, cria!'}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e, stack) {
      _log.severe('[REQ:$requestId] ✗ Erro ao registrar usuário', e, stack);
      return Response.internalServerError(
        body: jsonEncode({'error': 'Deu ruim no cadastro!'}),
      );
    }
  }

  // POST /auth/login
  Future<Response> login(Request request) async {
    final requestId = DateTime.now().millisecondsSinceEpoch.toString();
    _log.info('[REQ:$requestId] POST /auth/login - Tentativa de autenticação');

    try {
      final body = jsonDecode(await request.readAsString());
      final username = body['username'];

      _log.fine('[REQ:$requestId] Autenticando usuário: $username');

      final result = await _loginUsecase.execute(username, body['password']);

      if (result == null) {
        _log.warning(
          '[REQ:$requestId] ✗ Falha de autenticação para usuário: $username',
        );
        return Response.forbidden(
          jsonEncode({'error': 'Usuário ou senha inválidos!'}),
          headers: {'content-type': 'application/json'},
        );
      }

      _log.info(
        '[REQ:$requestId] ✓ Login realizado com sucesso: ${result.username}',
      );
      return Response.ok(
        jsonEncode({'token': result.token, 'username': result.username}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e, stack) {
      _log.severe('[REQ:$requestId] ✗ Erro no processo de login', e, stack);
      return Response.internalServerError();
    }
  }
}
