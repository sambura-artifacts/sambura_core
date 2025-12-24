/// Port (Interface) para serviço de autenticação e autorização.
///
/// Define o contrato para operações de JWT e autenticação.
abstract class AuthPort {
  /// Gera um token JWT para um usuário.
  ///
  /// [userId] - ID do usuário
  /// [username] - Nome do usuário
  /// [role] - Papel/role do usuário
  /// [claims] - Claims adicionais (opcional)
  /// Returns: Token JWT assinado
  String generateToken({
    required int userId,
    required String username,
    required String role,
    Map<String, dynamic>? claims,
  });

  /// Valida e decodifica um token JWT.
  ///
  /// [token] - Token JWT a validar
  /// Returns: Map com os claims do token
  /// Throws: Exception se token inválido ou expirado
  Map<String, dynamic> verifyToken(String token);

  /// Extrai o ID do usuário de um token.
  ///
  /// [token] - Token JWT
  /// Returns: ID do usuário ou null se inválido
  int? extractUserId(String token);

  /// Verifica se um token está expirado.
  ///
  /// [token] - Token JWT
  /// Returns: true se expirado
  bool isTokenExpired(String token);

  /// Renova um token JWT.
  ///
  /// [oldToken] - Token antigo
  /// Returns: Novo token com expiração renovada
  /// Throws: Exception se token inválido
  String refreshToken(String oldToken);
}
