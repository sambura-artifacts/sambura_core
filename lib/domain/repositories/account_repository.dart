import 'package:sambura_core/domain/barrel.dart';

abstract class AccountRepository {
  Future<void> create(AccountEntity account);

  Future<AccountEntity?> findByUsername(String username);
  Future<AccountEntity?> findById(int id);
  Future<AccountEntity?> findByExternalId(String externalId);
  Future<bool> existsByRole(String role);
}
