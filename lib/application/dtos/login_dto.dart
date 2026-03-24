/// DTO de entrada para login.
class LoginInput {
  final String username;
  final String password;

  const LoginInput({required this.username, required this.password});

  /// Validação básica
  bool get isValid => username.isNotEmpty && password.isNotEmpty;
}

/// DTO de saída para login.
class LoginOutput {
  final String token;
  final String username;
  final String role;
  final DateTime expiresAt;

  const LoginOutput({
    required this.token,
    required this.username,
    required this.role,
    required this.expiresAt,
  });

  Map<String, dynamic> toJson() => {
    'token': token,
    'username': username,
    'role': role,
    'expires_at': expiresAt.toIso8601String(),
  };
}
