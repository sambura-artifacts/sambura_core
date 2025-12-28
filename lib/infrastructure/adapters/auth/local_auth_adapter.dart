import 'package:sambura_core/application/auth/services/auth_service.dart';
import 'package:sambura_core/application/shared/ports/ports.dart';

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

      return int.tryParse(payload['sub']?.toString() ?? '');
    } catch (_) {
      return null;
    }
  }

  @override
  bool isTokenExpired(String token) {
    return _internalService.verifyToken(token) == null;
  }

  @override
  String refreshToken(String oldToken) {
    final payload = _internalService.verifyToken(oldToken);

    if (payload == null) {
      throw Exception('Não é possível renovar um token inválido ou expirado');
    }

    payload.remove('exp');
    payload.remove('iat');
    payload.remove('nbf');

    return _internalService.generateToken(payload);
  }
}
