import 'dart:convert';

class ExpenseLine {
  final String description;
  final double amount;

  ExpenseLine({required this.description, required this.amount});

  Map<String, dynamic> toMap() => {
        'description': description,
        'amount': amount,
      };

  factory ExpenseLine.fromMap(Map<String, dynamic> map) => ExpenseLine(
        description: map['description'],
        amount: (map['amount'] as num).toDouble(),
      );
}

class Expense {
  final String id;
  final double amount;
  final String currencyCode;
  final double? convertedAmount; // in company's currency
  final String? convertedCurrencyCode;
  final String category;
  final String description;
  final DateTime date;
  final String status; // pending, in_review, approved, rejected
  final String submittedById;
  final String companyId;
  final List<ExpenseLine> expenseLines;
  final String? receiptImagePath;
  final String? vendorName;
  final String? approvedById;
  final String? approvedByName;
  final DateTime createdAt;

  Expense({
    required this.id,
    required this.amount,
    required this.currencyCode,
    this.convertedAmount,
    this.convertedCurrencyCode,
    required this.category,
    required this.description,
    required this.date,
    required this.status,
    required this.submittedById,
    required this.companyId,
    this.expenseLines = const [],
    this.receiptImagePath,
    this.vendorName,
    this.approvedById,
    this.approvedByName,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'amount': amount,
        'currencyCode': currencyCode,
        'convertedAmount': convertedAmount,
        'convertedCurrencyCode': convertedCurrencyCode,
        'category': category,
        'description': description,
        'date': date.toIso8601String(),
        'status': status,
        'submittedById': submittedById,
        'companyId': companyId,
        'expenseLines': expenseLines.map((e) => e.toMap()).toList(),
        'receiptImagePath': receiptImagePath,
        'vendorName': vendorName,
        'approvedById': approvedById,
        'approvedByName': approvedByName,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Expense.fromMap(Map<String, dynamic> map) => Expense(
        id: map['id'],
        amount: (map['amount'] as num).toDouble(),
        currencyCode: map['currencyCode'],
        convertedAmount: map['convertedAmount'] != null
            ? (map['convertedAmount'] as num).toDouble()
            : null,
        convertedCurrencyCode: map['convertedCurrencyCode'],
        category: map['category'],
        description: map['description'],
        date: DateTime.parse(map['date']),
        status: map['status'],
        submittedById: map['submittedById'],
        companyId: map['companyId'],
        expenseLines: (map['expenseLines'] as List?)
                ?.map((e) => ExpenseLine.fromMap(e))
                .toList() ??
            [],
        receiptImagePath: map['receiptImagePath'],
        vendorName: map['vendorName'],
        approvedById: map['approvedById'],
        approvedByName: map['approvedByName'],
        createdAt: DateTime.parse(map['createdAt']),
      );

  String toJson() => json.encode(toMap());
  factory Expense.fromJson(String source) =>
      Expense.fromMap(json.decode(source));

  Expense copyWith({
    double? amount,
    String? currencyCode,
    double? convertedAmount,
    String? convertedCurrencyCode,
    String? category,
    String? description,
    DateTime? date,
    String? status,
    List<ExpenseLine>? expenseLines,
    String? receiptImagePath,
    String? vendorName,
    String? approvedById,
    String? approvedByName,
  }) =>
      Expense(
        id: id,
        amount: amount ?? this.amount,
        currencyCode: currencyCode ?? this.currencyCode,
        convertedAmount: convertedAmount ?? this.convertedAmount,
        convertedCurrencyCode:
            convertedCurrencyCode ?? this.convertedCurrencyCode,
        category: category ?? this.category,
        description: description ?? this.description,
        date: date ?? this.date,
        status: status ?? this.status,
        submittedById: submittedById,
        companyId: companyId,
        expenseLines: expenseLines ?? this.expenseLines,
        receiptImagePath: receiptImagePath ?? this.receiptImagePath,
        vendorName: vendorName ?? this.vendorName,
        approvedById: approvedById ?? this.approvedById,
        approvedByName: approvedByName ?? this.approvedByName,
        createdAt: createdAt,
      );
}
