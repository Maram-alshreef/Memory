import '../database/database_helper.dart';

class AuthUser {
  final int? id;
  final String name;
  final String email;
  final String password;

  const AuthUser({
    this.id,
    required this.name,
    required this.email,
    required this.password,
  });

  factory AuthUser.fromMap(Map<String, Object?> map) {
    return AuthUser(
      id: map['id'] as int?,
      name: map['name'] as String,
      email: map['email'] as String,
      password: map['password'] as String,
    );
  }
}

class AuthStore {
  AuthStore._();

  static final AuthStore instance = AuthStore._();
  final DatabaseHelper _database = DatabaseHelper.instance;

  Future<bool> emailExists(String email) {
    return _database.emailExists(email);
  }

  Future<bool> addUser(AuthUser user) async {
    if (await emailExists(user.email)) return false;

    await _database.insertUser({
      'name': user.name.trim(),
      'email': user.email.trim().toLowerCase(),
      'password': user.password,
    });
    return true;
  }

  Future<AuthUser?> findUser(String email, String password) async {
    final map = await _database.findUser(email, password);
    return map == null ? null : AuthUser.fromMap(map);
  }

  Future<bool> updatePassword(String email, String newPassword) async {
    final count = await _database.updateUserPassword(email, newPassword);
    return count > 0;
  }
}
