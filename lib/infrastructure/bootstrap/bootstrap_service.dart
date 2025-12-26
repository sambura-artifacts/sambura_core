import 'dart:math';
import 'package:logging/logging.dart';
import 'package:sambura_core/application/usecase/account/create_account_usecase.dart';
import 'package:sambura_core/domain/repositories/account_repository.dart';
import 'package:sambura_core/infrastructure/services/secrets/vault_service.dart';

class BootstrapService {
  final AccountRepository _accountRepository;
  final CreateAccountUsecase _createAccountUsecase;
  final VaultService _vaultService;
  final Logger _log = Logger('BootstrapService');

  BootstrapService(
    this._accountRepository,
    this._createAccountUsecase,
    this._vaultService,
  );

  /// Executa a verificação e criação do usuário administrador inicial.
  Future<void> run() async {
    try {
      _log.info('Verificando integridade das contas administrativas...');

      // Verifica se existe algum usuário com role 'admin'
      final hasAdmin = await _accountRepository.existsByRole('admin');

      if (hasAdmin) {
        _log.info(
          '🛡️ Admin local detectado. Ignorando processo de bootstrap.',
        );
        return;
      }

      _log.warning('⚠️ Nenhum administrador encontrado no banco de dados.');
      _log.info('Iniciando provisionamento do administrador de bootstrap...');

      final String username = 'admin';
      final String password = _generateSecurePassword();
      final String email = 'admin@sambura.io';

      // Executa a criação via UseCase para garantir a aplicação do Hash + Pepper
      await _createAccountUsecase.execute(
        username: username,
        password: password,
        email: email,
        role: 'admin',
      );

      // Persiste as credenciais geradas no Vault para acesso do operador
      await _vaultService.write('secret/data/sambura/bootstrap', {
        'username': username,
        'password': password,
        'generated_at': DateTime.now().toIso8601String(),
        'status': 'active',
      });

      _log.info(
        '✅ Usuário administrador criado e credenciais enviadas ao Vault.',
      );
    } catch (e, stack) {
      _log.severe('❌ Falha crítica no bootstrap do sistema.', e, stack);
      // O rethrow impede que o servidor suba sem um administrador válido
      rethrow;
    }
  }

  /// Gera uma sequência alfanumérica segura para a senha inicial.
  String _generateSecurePassword() {
    final random = Random.secure();
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#%&*';
    return List.generate(
      24,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }
}
