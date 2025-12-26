import 'dart:convert';
import 'package:sambura_core/infrastructure/api/presenter/auth/login_presenter.dart';
import 'package:sambura_core/infrastructure/api/presenter/auth/register_presenter.dart';
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

  // POST /api/v1/public/auth/register
  Future<Response> register(Request request) async {
    final requestId = DateTime.now().millisecondsSinceEpoch.toString();
    _log.info('[REQ:$requestId] Iniciando procedimento de registro.');

    try {
      final body = await request.readAsString();

      if (body.isEmpty) {
        return Response.badRequest(
          body: jsonEncode({
            'error': 'O corpo da requisição não pode estar vazio.',
          }),
          headers: {'content-type': 'application/json'},
        );
      }

      final data = jsonDecode(body);
      final String username = data['username'] ?? '';

      // Execução do Caso de Uso (Application Layer)
      await _createAccountUsecase.execute(
        username: username,
        password: data['password'] ?? '',
        email: data['email'] ?? '',
        role: data['role'] ?? 'developer',
      );

      _log.info(
        '[REQ:$requestId] Registro finalizado com sucesso para: $username',
      );

      return RegisterPresenter.success(username);
    } catch (e, stack) {
      _log.severe('[REQ:$requestId] Falha no registro de usuário.', e, stack);

      // Delegação da resposta de erro ao Presenter
      return RegisterPresenter.error(e);
    }
  }

  // POST /api/v1/public/auth/login
  Future<Response> login(Request request) async {
    final requestId = DateTime.now().millisecondsSinceEpoch.toString();
    _log.info('[REQ:$requestId] Recebida tentativa de login.');

    try {
      final bodyContent = await request.readAsString();
      if (bodyContent.isEmpty) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Corpo ausente'}),
        );
      }

      final body = jsonDecode(bodyContent);
      final username = body['username'] ?? '';
      final password = body['password'] ?? '';

      // Execução da lógica de negócio via UseCase
      final result = await _loginUsecase.execute(username, password);

      if (result == null) {
        _log.warning('[REQ:$requestId] Credenciais incorretas para: $username');
        return LoginPresenter.unauthorized();
      }

      _log.info('[REQ:$requestId] Autenticação bem-sucedida: $username');

      return LoginPresenter.success(result.token, result.username);
    } catch (e, stack) {
      _log.severe('[REQ:$requestId] Erro crítico no login.', e, stack);
      return LoginPresenter.error(e);
    }
  }
}
