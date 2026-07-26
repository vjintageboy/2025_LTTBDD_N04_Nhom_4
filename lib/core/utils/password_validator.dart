/// Rule for a "strong" password, enforced at account registration.
///
/// Requires at least 8 characters and all four character classes: an
/// uppercase letter, a lowercase letter, a digit and a special (non
/// alphanumeric) character.
bool isStrongPassword(String password) {
  return password.length >= 8 &&
      password.contains(RegExp(r'[A-Z]')) &&
      password.contains(RegExp(r'[a-z]')) &&
      password.contains(RegExp(r'[0-9]')) &&
      password.contains(RegExp(r'[^A-Za-z0-9]'));
}
