import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/expense.dart';
import '../services/currency_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

class ExpenseProvider extends ChangeNotifier {
  List<Expense> _expenses = [];
  bool _isLoading = false;
  final _uuid = const Uuid();

  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;

  List<Expense> getExpensesByUser(String userId) =>
      _expenses.where((e) => e.submittedById == userId).toList();

  List<Expense> getExpensesByStatus(String status) =>
      _expenses.where((e) => e.status == status).toList();

  List<Expense> getExpensesByUserAndStatus(String userId, String status) =>
      _expenses
          .where((e) => e.submittedById == userId && e.status == status)
          .toList();

  Expense? getExpenseById(String id) {
    try {
      return _expenses.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> loadExpenses(String companyId) async {
    _isLoading = true;
    notifyListeners();

    final storage = await StorageService.getInstance();
    final expensesData = await storage.getList(AppConstants.keyExpenses);
    _expenses = expensesData
        .map((e) => Expense.fromMap(e))
        .where((e) => e.companyId == companyId)
        .toList();
    _expenses.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    _isLoading = false;
    notifyListeners();
  }

  Future<Expense> submitExpense({
    required double amount,
    required String currencyCode,
    required String category,
    required String description,
    required DateTime date,
    required String submittedById,
    required String companyId,
    required String companyCurrencyCode,
    List<ExpenseLine> expenseLines = const [],
    String? receiptImagePath,
    String? vendorName,
  }) async {
    // Convert to company currency
    double? convertedAmount;
    if (currencyCode != companyCurrencyCode) {
      convertedAmount = await CurrencyService()
          .convertAmount(amount, currencyCode, companyCurrencyCode);
    }

    final expense = Expense(
      id: _uuid.v4(),
      amount: amount,
      currencyCode: currencyCode,
      convertedAmount: convertedAmount,
      convertedCurrencyCode:
          currencyCode != companyCurrencyCode ? companyCurrencyCode : null,
      category: category,
      description: description,
      date: date,
      status: AppConstants.statusPending,
      submittedById: submittedById,
      companyId: companyId,
      expenseLines: expenseLines,
      receiptImagePath: receiptImagePath,
      vendorName: vendorName,
    );

    _expenses.insert(0, expense);
    final storage = await StorageService.getInstance();
    await storage.addToList(AppConstants.keyExpenses, expense.toMap());
    notifyListeners();

    return expense;
  }

  Future<void> updateExpenseStatus(
    String expenseId,
    String status, {
    String? managerId,
    String? managerName,
  }) async {
    final index = _expenses.indexWhere((e) => e.id == expenseId);
    if (index == -1) return;

    final updated = _expenses[index].copyWith(
      status: status,
      approvedById: managerId ?? _expenses[index].approvedById,
      approvedByName: managerName ?? _expenses[index].approvedByName,
    );
    _expenses[index] = updated;

    final storage = await StorageService.getInstance();
    await storage.updateInList(
        AppConstants.keyExpenses, 'id', expenseId, updated.toMap());
    notifyListeners();
  }

  // Statistics
  int get totalExpenses => _expenses.length;
  int get pendingCount =>
      _expenses.where((e) => e.status == AppConstants.statusPending ||
          e.status == AppConstants.statusInReview).length;
  int get approvedCount =>
      _expenses.where((e) => e.status == AppConstants.statusApproved).length;
  int get rejectedCount =>
      _expenses.where((e) => e.status == AppConstants.statusRejected).length;

  double getTotalAmount(String currencyCode) => _expenses
      .where((e) => e.status == AppConstants.statusApproved)
      .fold(0.0, (sum, e) {
    if (e.convertedCurrencyCode == currencyCode) {
      return sum + (e.convertedAmount ?? e.amount);
    } else if (e.currencyCode == currencyCode) {
      return sum + e.amount;
    }
    return sum;
  });
}
