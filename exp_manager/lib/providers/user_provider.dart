import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

class UserProvider extends ChangeNotifier {
  List<User> _users = [];
  bool _isLoading = false;

  List<User> get users => _users;
  bool get isLoading => _isLoading;

  List<User> get managers =>
      _users.where((u) => u.role == AppConstants.roleManager).toList();

  List<User> get employees =>
      _users.where((u) => u.role == AppConstants.roleEmployee).toList();

  List<User> getUsersByCompany(String companyId) =>
      _users.where((u) => u.companyId == companyId).toList();

  User? getUserById(String id) {
    try {
      return _users.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> loadUsers(String companyId) async {
    _isLoading = true;
    notifyListeners();

    final storage = await StorageService.getInstance();
    final usersData = await storage.getList(AppConstants.keyUsers);
    _users = usersData
        .map((u) => User.fromMap(u))
        .where((u) => u.companyId == companyId)
        .toList();

    _isLoading = false;
    notifyListeners();
  }

  Future<User?> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
    required String companyId,
    String? managerId,
  }) async {
    final user = await AuthService().createUser(
      name: name,
      email: email,
      password: password,
      role: role,
      companyId: companyId,
      managerId: managerId,
    );

    if (user != null) {
      _users.add(user);
      notifyListeners();
    }
    return user;
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    final index = _users.indexWhere((u) => u.id == userId);
    if (index == -1) return;

    final updated = _users[index].copyWith(role: newRole);
    _users[index] = updated;

    final storage = await StorageService.getInstance();
    await storage.updateInList(
        AppConstants.keyUsers, 'id', userId, updated.toMap());
    notifyListeners();
  }

  Future<void> updateUserManager(String userId, String? managerId) async {
    final index = _users.indexWhere((u) => u.id == userId);
    if (index == -1) return;

    final updated = managerId == null
        ? _users[index].copyWith(clearManager: true)
        : _users[index].copyWith(managerId: managerId);
    _users[index] = updated;

    final storage = await StorageService.getInstance();
    await storage.updateInList(
        AppConstants.keyUsers, 'id', userId, updated.toMap());
    notifyListeners();
  }

  Future<void> deleteUser(String userId) async {
    _users.removeWhere((u) => u.id == userId);
    final storage = await StorageService.getInstance();
    await storage.removeFromList(AppConstants.keyUsers, 'id', userId);
    notifyListeners();
  }
}
