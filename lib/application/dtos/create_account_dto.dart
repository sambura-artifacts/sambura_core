/// DTO de entrada para criar conta.
class CreateAccountInput {
  final String username;
  final String password;
  final String email;
  final String role;

  const CreateAccountInput({
    required this.username,
    required this.password,
    required this.email,
    this.role = 'developer',
  });

  /// Validação básica
  bool get isValid {
    return username.isNotEmpty &&
        password.length >= 6 &&
        email.contains('@') &&
        (role == 'admin' || role == 'developer');
  }

  /// Mensagens de validação
  String? validate() {
    if (username.isEmpty) return 'Username is required';
    if (username.length < 3) return 'Username must be at least 3 characters';
    if (password.length < 6) return 'Password must be at least 6 characters';
    if (!email.contains('@')) return 'Invalid email format';
    if (role != 'admin' && role != 'developer') return 'Invalid role';
    return null;
  }
}

/// DTO de saída para criar conta.
class CreateAccountOutput {
  final int accountId;
  final String username;
  final String email;
  final String role;
  final DateTime createdAt;

  const CreateAccountOutput({
    required this.accountId,
    required this.username,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'account_id': accountId,
    'username': username,
    'email': email,
    'role': role,
    'created_at': createdAt.toIso8601String(),
  };
}
