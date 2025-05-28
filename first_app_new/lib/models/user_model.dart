class User {
  final String id;
  final String name;
  final String? email;
  final String? avatar;
  final String role;
  final bool isOnline;

  User({
    required this.id,
    required this.name,
    this.email,
    this.avatar,
    required this.role,
    this.isOnline = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? json['username'] ?? 'Unknown User',
      email: json['email'],
      avatar: json['avatar'] ?? json['image'],
      role: json['role'] ?? 'user',
      isOnline: json['isOnline'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'role': role,
      'isOnline': isOnline,
    };
  }
}
