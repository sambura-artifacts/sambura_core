import 'package:sambura_core/application/shared/ports/ports.dart';

class InMemoryCacheAdapter extends CachePort {
  final Map<String, dynamic> _storage = {};
  final Set<String> _locks = {};

  @override
  Future<bool> acquireLock(String key, {Duration? duration}) async {
    if (_locks.contains(key)) return false;
    _locks.add(key);
    return true;
  }

  @override
  Future<void> releaseLock(String key) async {
    _locks.remove(key);
  }

  @override
  Future<void> set(String key, dynamic value, {Duration? ttl}) async {
    _storage[key] = value;
  }

  @override
  Future<String?> get(String key) async => _storage[key];

  void clear() {
    _storage.clear();
    _locks.clear();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
