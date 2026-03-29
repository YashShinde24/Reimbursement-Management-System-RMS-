import 'dart:convert';

class Company {
  final String id;
  final String name;
  final String country;
  final String currencyCode;
  final String currencyName;
  final String currencySymbol;
  final DateTime createdAt;

  Company({
    required this.id,
    required this.name,
    required this.country,
    required this.currencyCode,
    required this.currencyName,
    required this.currencySymbol,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'country': country,
        'currencyCode': currencyCode,
        'currencyName': currencyName,
        'currencySymbol': currencySymbol,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Company.fromMap(Map<String, dynamic> map) => Company(
        id: map['id'],
        name: map['name'],
        country: map['country'],
        currencyCode: map['currencyCode'],
        currencyName: map['currencyName'],
        currencySymbol: map['currencySymbol'],
        createdAt: DateTime.parse(map['createdAt']),
      );

  String toJson() => json.encode(toMap());
  factory Company.fromJson(String source) =>
      Company.fromMap(json.decode(source));

  Company copyWith({
    String? name,
    String? country,
    String? currencyCode,
    String? currencyName,
    String? currencySymbol,
  }) =>
      Company(
        id: id,
        name: name ?? this.name,
        country: country ?? this.country,
        currencyCode: currencyCode ?? this.currencyCode,
        currencyName: currencyName ?? this.currencyName,
        currencySymbol: currencySymbol ?? this.currencySymbol,
        createdAt: createdAt,
      );
}
