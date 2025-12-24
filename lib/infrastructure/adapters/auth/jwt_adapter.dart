import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:logging/logging.dart';
import 'package:sambura_core/config/logger.dart';
import 'package:sambura_core/application/ports/auth_port.dart';

/// Adapter para JWT implementando IAuthPort.
///
/// Segue o padrão Hexagonal Architecture (Ports & Adapters).
class JwtAdapter implements IAuthPort {
  final String _secret;
  final Duration _tokenDuration;
  final Logger _log = LoggerConfig.getLogger('JwtAdapter');

  JwtAdapter({
    required String secret,
    Duration tokenDuration = const Duration(hours: 24),
  }) : _secret = secret,
       _tokenDuration = tokenDuration;

  @override
  String generateToken({
    required int userId,
    required String username,
    required String role,
    Map<String, dynamic>? claims,
  }) {
    try {
      final issuedAt = DateTime.now();
      final expiresAt = issuedAt.add(_tokenDuration);

      final jwt = JWT({
        'user_id': userId,
        'username': username,
        'role': role,
        'iat': issuedAt.millisecondsSinceEpoch ~/ 1000,
        'exp': expiresAt.millisecondsSinceEpoch ~/ 1000,
        ...?claims,
      });

      final token = jwt.sign(SecretKey(_secret), algorithm: JWTAlgorithm.HS256);

      _log.fine('✅ Token generated for user: $username');
      return token;
    } catch (e, stack) {
      _log.severe('❌ Failed to generate token: $e', e, stack);
      rethrow;
    }
  }

  @override
  Map<String, dynamic> verifyToken(String token) {
    try {
      final jwt = JWT.verify(token, SecretKey(_secret));

      _log.fine('✅ Token verified successfully');
      return jwt.payload as Map<String, dynamic>;
    } on JWTExpiredException {
      _log.warning('⚠️  Token expired');
      throw Exception('Token expired');
    } on JWTException catch (e) {
      _log.warning('⚠️  Invalid token: $e');
      throw Exception('Invalid token');
    } catch (e, stack) {
      _log.severe('❌ Failed to verify token: $e', e, stack);
      throw Exception('Failed to verify token');
    }
  }

  @override
  int? extractUserId(String token) {
    try {
      final payload = verifyToken(token);
      return payload['user_id'] as int?;
    } catch (e) {
      _log.fine('Failed to extract user ID from token');
      return null;
    }
  }

  @override
  bool isTokenExpired(String token) {
    try {
      verifyToken(token);
      return false;
    } on JWTExpiredException {
      return true;
    } catch (e) {
      return true;
    }
  }

  @override
  String refreshToken(String oldToken) {
    try {
      final payload = verifyToken(oldToken);

      return generateToken(
        userId: payload['user_id'] as int,
        username: payload['username'] as String,
        role: payload['role'] as String,
      );
    } catch (e, stack) {
      _log.severe('❌ Failed to refresh token: $e', e, stack);
      throw Exception('Failed to refresh token');
    }
  }
}
