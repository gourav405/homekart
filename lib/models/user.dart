class User {
  final int id;
  final String username;
  final String role;

  User({required this.id, required this.username, required this.role});

  factory User.fromMap(Map<String, String?> map) {
    return User(
      id: int.parse(map['id']!),
      username: map['username']!,
      role: map['role']!,
    );
  }

  bool get isAdmin => role == 'admin';
}
