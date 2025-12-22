import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:logging/logging.dart';
import 'package:sambura_core/config/logger.dart';

class AuthService {
  final String _jwtSecret;
  final Logger _log = LoggerConfig.getLogger('AuthService');

  AuthService(this._jwtSecret);

  String? verifyToken(String token) {
    try {
      final jwt = JWT.verify(
        token,
        SecretKey(_jwtSecret),
        issuer: 'sambura-auth',
      );
      _log.fine('✅ Token validado com sucesso para o ID: ${jwt.subject}');
      return jwt.subject;
    } on JWTExpiredException {
      _log.warning('⚠️ O token do cria expirou!');
      return null;
    } on JWTException catch (e) {
      _log.severe('🔥 Token inválido ou falsificado: ${e.message}');
      return null;
    } catch (e) {
      _log.severe('💥 Erro desconhecido na validação do token: $e');
      return null;
    }
  }

  Map<String, dynamic>? getPayload(String token) {
    try {
      final jwt = JWT.verify(token, SecretKey(_jwtSecret));
      return jwt.payload as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
