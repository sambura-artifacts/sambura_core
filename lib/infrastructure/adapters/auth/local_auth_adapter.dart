import 'package:sambura_core/application/ports/auth_port.dart';
import 'package:sambura_core/infrastructure/services/auth/auth_service.dart';

class LocalAuthAdapter implements AuthPort {
  final AuthService _internalService;

  LocalAuthAdapter(this._internalService);

  @override
  String generateToken({
    required int userId,
    required String username,
    required String role,
    Map<String, dynamic>? claims,
  }) {
    // Monta o payload seguindo padrões OIDC (sub para ID)
    final payload = {
      'sub': userId.toString(),
      'username': username,
      'role': role,
      ...?claims,
    };

    return _internalService.generateToken(payload);
  }

  @override
  Map<String, dynamic> verifyToken(String token) {
    final payload = _internalService.verifyToken(token);

    if (payload == null) {
      throw Exception('Token inválido ou expirado');
    }

    return payload;
  }

  @override
  int? extractUserId(String token) {
    try {
      final payload = _internalService.verifyToken(token);
      if (payload == null) return null;

      // Tenta extrair do 'sub' (padrão do seu AuthService refatorado)
      return int.tryParse(payload['sub']?.toString() ?? '');
    } catch (_) {
      return null;
    }
  }

  @override
  bool isTokenExpired(String token) {
    // O seu AuthService já loga e retorna null se expirar
    return _internalService.verifyToken(token) == null;
  }

  @override
  String refreshToken(String oldToken) {
    final payload = _internalService.verifyToken(oldToken);

    if (payload == null) {
      throw Exception('Não é possível renovar um token inválido ou expirado');
    }

    // Remove claims temporais para que o sign() gere novos (iat, exp, nbf)
    payload.remove('exp');
    payload.remove('iat');
    payload.remove('nbf');

    return _internalService.generateToken(payload);
  }
}
