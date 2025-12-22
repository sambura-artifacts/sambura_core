import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:logging/logging.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/application/usecase/create_account_usecase.dart';
import 'package:sambura_core/application/usecase/login_usecase.dart';

class AuthController {
  final CreateAccountUsecase _createAccountUsecase;
  final LoginUsecase _loginUsecase;
  final Logger _log = LoggerConfig.getLogger('AuthController');

  AuthController(this._createAccountUsecase, this._loginUsecase);

  // POST /auth/register
  Future<Response> register(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString());

      await _createAccountUsecase.execute(
        username: body['username'],
        password: body['password'],
        email: body['email'],
        role: body['role'] ?? 'developer',
      );

      _log.info('👤 Novo usuário registrado: ${body['username']}');
      return Response.ok(
        jsonEncode({'message': 'Usuário criado com sucesso, cria!'}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      _log.severe('🔥 Erro no registro: $e');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Deu ruim no cadastro!'}),
      );
    }
  }

  // POST /auth/login
  Future<Response> login(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString());

      final result = await _loginUsecase.execute(
        body['username'],
        body['password'],
      );

      if (result == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Usuário ou senha inválidos!'}),
          headers: {'content-type': 'application/json'},
        );
      }

      _log.info('🔑 Login realizado: ${result.username}');
      return Response.ok(
        jsonEncode({'token': result.token, 'username': result.username}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      _log.severe('🔥 Erro no login: $e');
      return Response.internalServerError();
    }
  }
}
