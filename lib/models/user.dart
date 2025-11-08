class User {
  final String id;
  final String name;
  final String email;
  final String? phoneNumber; // camelCase in Dart
  final String? department;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.department,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] ?? json['user_id'] ?? '').toString(),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number']?.toString(),
      department: json['department']?.toString(),
    );
  }
}
