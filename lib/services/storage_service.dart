import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';

class StorageService {
  final _secureStorage = const FlutterSecureStorage();

  static const String _userKey = 'user_data';
  static const String _authAliasPrefix = 'auth_alias';

  Future<void> saveUser(User user) async {
    try {
      final userJson = jsonEncode(user.toJson());
      await _secureStorage.write(key: _userKey, value: userJson);
    } catch (e) {
      throw Exception('Failed to save user: $e');
    }
  }

  Future<User?> getUser() async {
    try {
      final userJson = await _secureStorage.read(key: _userKey);
      if (userJson != null) {
        final jsonData = jsonDecode(userJson) as Map<String, dynamic>;
        return User.fromJson(jsonData);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to retrieve user: $e');
    }
  }

  Future<void> clear() async {
    try {
      await _secureStorage.delete(key: _userKey);
    } catch (e) {
      throw Exception('Failed to clear storage: $e');
    }
  }

  Future<void> clearAll() async {
    try {
      await _secureStorage.deleteAll();
    } catch (e) {
      throw Exception('Failed to clear all storage: $e');
    }
  }

  Future<void> saveAuthAlias({
    required UserType type,
    required String identifier,
    required String authEmail,
  }) async {
    final normalizedIdentifier = _normalizeIdentifier(identifier);
    if (normalizedIdentifier.isEmpty || authEmail.trim().isEmpty) {
      return;
    }
    final key = _aliasKey(type, normalizedIdentifier);
    await _secureStorage.write(key: key, value: authEmail.trim().toLowerCase());
  }

  Future<String?> getAuthAlias({
    required UserType type,
    required String identifier,
  }) async {
    final normalizedIdentifier = _normalizeIdentifier(identifier);
    if (normalizedIdentifier.isEmpty) {
      return null;
    }
    final key = _aliasKey(type, normalizedIdentifier);
    return _secureStorage.read(key: key);
  }

  String _aliasKey(UserType type, String normalizedIdentifier) {
    return '$_authAliasPrefix.${type.name}.$normalizedIdentifier';
  }

  String _normalizeIdentifier(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }
}
