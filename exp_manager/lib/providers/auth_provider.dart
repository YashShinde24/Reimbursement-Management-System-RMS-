import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/company.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  Company? _currentCompany;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  Company? get currentCompany => _currentCompany;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isManager => _currentUser?.isManager ?? false;
  bool get isEmployee => _currentUser?.isEmployee ?? false;

  final AuthService _authService = AuthService();

  Future<void> checkSession() async {
    _isLoading = true;
    notifyListeners();

    final user = await _authService.getCurrentUser();
    if (user != null) {
      _currentUser = user;
      await _loadCompany(user.companyId);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> signUp({
    required String companyName,
    required String adminName,
    required String email,
    required String password,
    required String country,
    required String currencyCode,
    required String currencyName,
    required String currencySymbol,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authService.signUp(
      companyName: companyName,
      adminName: adminName,
      email: email,
      password: password,
      country: country,
      currencyCode: currencyCode,
      currencyName: currencyName,
      currencySymbol: currencySymbol,
    );

    if (result != null) {
      _currentUser = result.user;
      _currentCompany = result.company;
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _error = 'Email already taken';
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final user = await _authService.login(email, password);
    if (user != null) {
      _currentUser = user;
      await _loadCompany(user.companyId);
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _error = 'Invalid email or password';
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    _currentCompany = null;
    _error = null;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    if (_currentUser == null) return;
    final user = await _authService.getCurrentUser();
    if (user != null) {
      _currentUser = user;
      notifyListeners();
    }
  }

  Future<void> _loadCompany(String companyId) async {
    final storage = await StorageService.getInstance();
    final companies = await storage.getList(AppConstants.keyCompanies);
    try {
      final companyData =
          companies.firstWhere((c) => c['id'] == companyId);
      _currentCompany = Company.fromMap(companyData);
    } catch (_) {}
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
