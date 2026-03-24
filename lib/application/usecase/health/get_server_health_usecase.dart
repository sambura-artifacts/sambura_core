import 'package:sambura_core/application/services/health/health_check_service.dart';

class GetServerHealthUseCase {
  final HealthCheckService _healthCheckService;

  GetServerHealthUseCase(this._healthCheckService);
  Future<Map<String, dynamic>> execute() async {
    return await _healthCheckService.checkAll();
  }
}
