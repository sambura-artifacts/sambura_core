import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:sambura_core/infrastructure/services/hash_service.dart';
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

  LoginUsecase(this._repo, this._hashService, this._jwtSecret);

  Future<LoginResult?> execute(String username, String password) async {
    final account = await _repo.findByUsername(username);
    if (account == null) return null;

    final isValid = _hashService.verify(password, account.passwordHash);
    if (!isValid) return null;

    final jwt = JWT(
      {'role': account.role, 'email': account.email},
      issuer: 'sambura-auth',
      subject: account.id.toString(),
    );

    final token = jwt.sign(
      SecretKey(_jwtSecret),
      expiresIn: const Duration(days: 1),
    );

    return LoginResult(token, account.username);
  }
}
