import 'dart:convert';
import 'package:crypto/crypto.dart' show md5;
import 'package:uuid/uuid.dart';
import '../models/user.dart';
import '../models/company.dart';
import '../utils/constants.dart';
import 'storage_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;
  AuthService._();

  final _uuid = const Uuid();

  String _hashPassword(String password) {
    // Simple hash for demo (use bcrypt in production)
    return md5.convert(utf8.encode(password)).toString();
  }

  Future<({User user, Company company})?> signUp({
    required String companyName,
    required String adminName,
    required String email,
    required String password,
    required String country,
    required String currencyCode,
    required String currencyName,
    required String currencySymbol,
  }) async {
    final storage = await StorageService.getInstance();

    // Check if email already exists
    final users = await storage.getList(AppConstants.keyUsers);
    if (users.any((u) => u['email'] == email)) {
      return null; // Email already taken
    }

    // Create company
    final company = Company(
      id: _uuid.v4(),
      name: companyName,
      country: country,
      currencyCode: currencyCode,
      currencyName: currencyName,
      currencySymbol: currencySymbol,
    );

    // Create admin user
    final user = User(
      id: _uuid.v4(),
      name: adminName,
      email: email,
      passwordHash: _hashPassword(password),
      role: AppConstants.roleAdmin,
      companyId: company.id,
    );

    await storage.addToList(AppConstants.keyCompanies, company.toMap());
    await storage.addToList(AppConstants.keyUsers, user.toMap());
    await storage.setString(AppConstants.keyCurrentUser, user.id);

    return (user: user, company: company);
  }

  Future<User?> login(String email, String password) async {
    final storage = await StorageService.getInstance();
    final users = await storage.getList(AppConstants.keyUsers);
    final passwordHash = _hashPassword(password);

    try {
      final userData = users.firstWhere(
        (u) => u['email'] == email && u['passwordHash'] == passwordHash,
      );
      final user = User.fromMap(userData);
      await storage.setString(AppConstants.keyCurrentUser, user.id);
      return user;
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    final storage = await StorageService.getInstance();
    await storage.remove(AppConstants.keyCurrentUser);
  }

  Future<User?> getCurrentUser() async {
    final storage = await StorageService.getInstance();
    final userId = await storage.getString(AppConstants.keyCurrentUser);
    if (userId == null) return null;

    final users = await storage.getList(AppConstants.keyUsers);
    try {
      final userData = users.firstWhere((u) => u['id'] == userId);
      return User.fromMap(userData);
    } catch (_) {
      return null;
    }
  }

  Future<User?> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
    required String companyId,
    String? managerId,
  }) async {
    final storage = await StorageService.getInstance();

    // Check if email already exists
    final users = await storage.getList(AppConstants.keyUsers);
    if (users.any((u) => u['email'] == email)) {
      return null;
    }

    final user = User(
      id: _uuid.v4(),
      name: name,
      email: email,
      passwordHash: _hashPassword(password),
      role: role,
      companyId: companyId,
      managerId: managerId,
    );

    await storage.addToList(AppConstants.keyUsers, user.toMap());
    return user;
  }
}
