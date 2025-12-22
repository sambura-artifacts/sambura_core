// lib/application/usecase/create_account_usecase.dart
import 'package:sambura_core/infrastructure/services/hash_service.dart';
import 'package:sambura_core/domain/repositories/account_repository.dart';

class CreateAccountUsecase {
  final AccountRepository _repo;
  final HashService _hashService;

  CreateAccountUsecase(this._repo, this._hashService);

  Future<void> execute({
    required String username,
    required String password,
    required String email,
    String role = 'developer',
  }) async {
    final passwordHash = _hashService.hashPassword(password);

    await _repo.create(
      username: username,
      passwordHash: passwordHash,
      email: email,
      role: role,
    );
  }
}
