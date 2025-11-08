class Department {
  final String code;
  final String name;

  Department({required this.code, required this.name});

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      code: (json['code'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
    );
  }

  @override
  String toString() => '$code - $name';
}
