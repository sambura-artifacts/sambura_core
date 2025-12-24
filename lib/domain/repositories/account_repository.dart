import 'package:sambura_core/domain/entities/account_entity.dart';

abstract class AccountRepository {
  Future<void> create(AccountEntity account);

  Future<AccountEntity?> findByUsername(String username);
  Future<AccountEntity?> findById(int id);
  Future<AccountEntity?> findByExternalId(String externalId);
}
