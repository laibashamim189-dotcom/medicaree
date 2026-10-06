class AdminCredentials {
  final String email;
  final String password;

  AdminCredentials({
    required this.email,
    required this.password,
  });
}

class LoginResult {
  final bool isSuccess;
  final String? errorMessage;

  LoginResult({
    required this.isSuccess,
    this.errorMessage,
  });
}