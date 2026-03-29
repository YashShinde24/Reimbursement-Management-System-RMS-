import 'dart:convert';

class User {
  final String id;
  final String name;
  final String email;
  final String passwordHash;
  final String role; // 'admin', 'manager', 'employee'
  final String companyId;
  final String? managerId;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    required this.role,
    required this.companyId,
    this.managerId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isAdmin => role == 'admin';
  bool get isManager => role == 'manager';
  bool get isEmployee => role == 'employee';

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'passwordHash': passwordHash,
        'role': role,
        'companyId': companyId,
        'managerId': managerId,
        'createdAt': createdAt.toIso8601String(),
      };

  factory User.fromMap(Map<String, dynamic> map) => User(
        id: map['id'],
        name: map['name'],
        email: map['email'],
        passwordHash: map['passwordHash'],
        role: map['role'],
        companyId: map['companyId'],
        managerId: map['managerId'],
        createdAt: DateTime.parse(map['createdAt']),
      );

  String toJson() => json.encode(toMap());
  factory User.fromJson(String source) => User.fromMap(json.decode(source));

  User copyWith({
    String? name,
    String? email,
    String? passwordHash,
    String? role,
    String? managerId,
    bool clearManager = false,
  }) =>
      User(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        passwordHash: passwordHash ?? this.passwordHash,
        role: role ?? this.role,
        companyId: companyId,
        managerId: clearManager ? null : (managerId ?? this.managerId),
        createdAt: createdAt,
      );
}
