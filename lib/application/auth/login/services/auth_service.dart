import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:logging/logging.dart';
import 'package:sambura_core/config/logger.dart';

class AuthService {
  final String _jwtSecret;
  final Logger _log = LoggerConfig.getLogger('AuthService');
  final String _issuer = 'sambura-auth';

  AuthService(this._jwtSecret);

  /// Gera um novo Token JWT
  String generateToken(Map<String, dynamic> payload) {
    final jwt = JWT(payload, issuer: _issuer, subject: payload['sub']);

    return jwt.sign(
      SecretKey(_jwtSecret),
      expiresIn: const Duration(hours: 24),
    );
  }

  Map<String, dynamic>? verifyToken(String token) {
    try {
      final jwt = JWT.verify(token, SecretKey(_jwtSecret), issuer: _issuer);

      _log.fine('✅ Token validado com sucesso para o ID: ${jwt.subject}');

      return {...jwt.payload as Map<String, dynamic>, 'sub': jwt.subject};
    } on JWTExpiredException {
      _log.warning('⚠️ O token expirou!');
      return null;
    } on JWTException catch (e) {
      _log.severe('🔥 Token inválido ou falsificado: ${e.message}');
      return null;
    } catch (e) {
      _log.severe('💥 Erro desconhecido: $e');
      return null;
    }
  }
}
