import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:logging/logging.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/infrastructure/services/auth/hash_service.dart';
import 'package:sambura_core/domain/repositories/account_repository.dart';

class LoginResult {
  final String token;
  final String username;

  LoginResult(this.token, this.username);
}

class LoginUsecase {
  final AccountRepository _repo;
  final HashService _hashService;
  final String _jwtSecret;
  final Logger _log = LoggerConfig.getLogger('LoginUsecase');

  LoginUsecase(this._repo, this._hashService, this._jwtSecret);

  Future<LoginResult?> execute(String username, String password) async {
    _log.info('Executando autenticação para usuário: $username');

    try {
      _log.fine('Buscando conta no repositório: $username');
      final account = await _repo.findByUsername(username);

      if (account == null) {
        _log.warning('✗ Conta não encontrada: $username');
        return null;
      }

      _log.fine('Verificando hash da senha');
      final isValid = _hashService.verify(password, account.passwordHash);

      if (!isValid) {
        _log.warning('✗ Senha inválida para usuário: $username');
        return null;
      }

      _log.fine('Gerando JWT token');
      final payload = {
        'sub': account.externalId.value, // .value extrai a String
        'username': account.username.value,
        'role': account.role.value,
      };
      final jwt = JWT(
        payload,
        issuer: 'sambura-auth',
        subject: account.id.toString(),
      );

      final token = jwt.sign(
        SecretKey(_jwtSecret),
        expiresIn: const Duration(days: 1),
      );

      _log.info(
        '✓ Autenticação bem-sucedida: $username (role: ${account.role})',
      );
      return LoginResult(token, account.usernameValue);
    } catch (e, stack) {
      _log.severe('✗ Erro durante autenticação para: $username', e, stack);
      rethrow;
    }
  }
}
