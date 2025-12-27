// lib/application/usecase/create_account_usecase.dart
import 'package:logging/logging.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/application/ports/ports.dart';
import 'package:sambura_core/domain/entities/entities.dart';
import 'package:sambura_core/domain/repositories/repositories.dart';

class CreateAccountUsecase {
  final AccountRepository _repo;
  final HashPort _hash;
  final Logger _log = LoggerConfig.getLogger('CreateAccountUsecase');

  CreateAccountUsecase(this._repo, this._hash);

  Future<void> execute({
    required String username,
    required String password,
    required String email,
    String role = 'developer',
  }) async {
    _log.info(
      'Criando nova conta: username=$username, email=$email, role=$role',
    );

    try {
      _log.fine('Gerando hash da senha');
      final passwordHash = _hash.hashPassword(password);

      final account = AccountEntity.create(
        username: username,
        password: passwordHash,
        email: email,
        role: role,
      );

      _log.fine('Salvando conta no repositório');
      await _repo.create(account);

      _log.info('✓ Conta criada com sucesso: $username');
    } catch (e, stack) {
      _log.severe('✗ Erro ao criar conta para: $username', e, stack);
      rethrow;
    }
  }
}
