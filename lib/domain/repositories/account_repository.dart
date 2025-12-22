import 'package:sambura_core/domain/entities/account_entity.dart';

abstract class AccountRepository {
  Future<void> create({
    required String username,
    required String passwordHash,
    required String email,
    required String role,
  });

  Future<AccountEntity?> findByUsername(String username);
  Future<AccountEntity?> findById(int id);
}
