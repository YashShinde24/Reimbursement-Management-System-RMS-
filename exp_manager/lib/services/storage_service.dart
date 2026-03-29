import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static StorageService? _instance;
  late SharedPreferences _prefs;

  StorageService._();

  static Future<StorageService> getInstance() async {
    if (_instance == null) {
      _instance = StorageService._();
      _instance!._prefs = await SharedPreferences.getInstance();
    }
    return _instance!;
  }

  // Generic list operations
  Future<List<Map<String, dynamic>>> getList(String key) async {
    final data = _prefs.getString(key);
    if (data == null) return [];
    return List<Map<String, dynamic>>.from(json.decode(data));
  }

  Future<void> saveList(String key, List<Map<String, dynamic>> list) async {
    await _prefs.setString(key, json.encode(list));
  }

  Future<void> addToList(String key, Map<String, dynamic> item) async {
    final list = await getList(key);
    list.add(item);
    await saveList(key, list);
  }

  Future<void> updateInList(
      String key, String idField, String idValue, Map<String, dynamic> item) async {
    final list = await getList(key);
    final index = list.indexWhere((e) => e[idField] == idValue);
    if (index != -1) {
      list[index] = item;
      await saveList(key, list);
    }
  }

  Future<void> removeFromList(
      String key, String idField, String idValue) async {
    final list = await getList(key);
    list.removeWhere((e) => e[idField] == idValue);
    await saveList(key, list);
  }

  // Single value operations
  Future<String?> getString(String key) async => _prefs.getString(key);
  Future<void> setString(String key, String value) async =>
      await _prefs.setString(key, value);
  Future<void> remove(String key) async => await _prefs.remove(key);

  Future<void> clearAll() async => await _prefs.clear();
}
