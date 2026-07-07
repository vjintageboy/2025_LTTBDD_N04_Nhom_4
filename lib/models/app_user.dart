class AppUser {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final UserRole role;
  final int streakCount;
  final DateTime? createdAt;

  AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.role,
    this.streakCount = 0,
    this.createdAt,
  });

  factory AppUser.fromMap(Map<String, dynamic> data) {
    return AppUser(
      id: data['id'] ?? '',
      email: data['email'] ?? '',
      displayName: data['full_name'] ?? '',
      photoUrl: data['avatar_url'],
      role: UserRole.fromString(data['role'] ?? 'user'),
      streakCount: data['streak_count'] ?? 0,
      createdAt: data['created_at'] != null
          ? DateTime.tryParse(data['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'full_name': displayName,
      'avatar_url': photoUrl,
      'role': role.value,
      'streak_count': streakCount,
    };
  }

  bool get isAdmin => role == UserRole.admin;

  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    UserRole? role,
    int? streakCount,
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      streakCount: streakCount ?? this.streakCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

enum UserRole {
  admin('admin'),
  user('user');

  final String value;
  const UserRole(this.value);

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.user,
    );
  }

  @override
  String toString() => value;

  // Helper getters
  bool get isAdmin => this == UserRole.admin;
  bool get isUser => this == UserRole.user;
}
