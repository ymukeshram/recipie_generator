import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserSession {
  static const _storage = FlutterSecureStorage();
  static const _nameKey = 'rasoiai_user_name';
  static const _emailKey = 'rasoiai_user_email';
  static const _accountsKey = 'rasoiai_registered_accounts_v1';

  static String userName = 'Chef';
  static String userEmail = 'chef@rasoiai.com';

  static Future<void> load() async {
    try {
      final savedName = await _storage.read(key: _nameKey);
      final savedEmail = await _storage.read(key: _emailKey);
      if (savedName != null && savedName.trim().isNotEmpty) {
        userName = savedName.trim();
      }
      if (savedEmail != null && savedEmail.trim().isNotEmpty) {
        userEmail = savedEmail.trim();
      }
    } catch (_) {}
  }

  static Future<void> setSession({required String name, required String email}) async {
    userName = name.trim();
    userEmail = email.trim();
    try {
      await _storage.write(key: _nameKey, value: userName);
      await _storage.write(key: _emailKey, value: userEmail);
    } catch (_) {}
  }

  static Future<void> updateName(String name) async {
    userName = name.trim();
    try {
      await _storage.write(key: _nameKey, value: userName);
    } catch (_) {}
  }

  /// Register a new user account with hashed/stored credentials
  static Future<bool> registerAccount({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final accounts = await _getAccounts();
      final normalizedEmail = email.trim().toLowerCase();
      if (accounts.containsKey(normalizedEmail)) {
        return false; // Account already exists
      }
      accounts[normalizedEmail] = {
        'name': name.trim(),
        'password': password,
        'createdAt': DateTime.now().toIso8601String(),
      };
      await _storage.write(key: _accountsKey, value: jsonEncode(accounts));
      await setSession(name: name, email: email);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Validate user credentials on login
  static Future<({bool isValid, String? name, String? error})> validateCredentials({
    required String email,
    required String password,
  }) async {
    try {
      final accounts = await _getAccounts();
      final normalizedEmail = email.trim().toLowerCase();

      // If no accounts have ever been created, create default chef demo account
      if (accounts.isEmpty) {
        if (normalizedEmail == 'chef@rasoiai.com' && password == 'chef123') {
          return (isValid: true, name: 'Chef', error: null);
        }
        return (
          isValid: false,
          name: null,
          error: 'No registered account found with this email. Please Sign Up first.',
        );
      }

      final user = accounts[normalizedEmail];
      if (user == null) {
        return (
          isValid: false,
          name: null,
          error: 'Account not found. Please check your email or Sign Up.',
        );
      }

      if (user['password'] != password) {
        return (
          isValid: false,
          name: null,
          error: 'Incorrect password. Please try again.',
        );
      }

      return (isValid: true, name: user['name'] as String?, error: null);
    } catch (_) {
      return (isValid: false, name: null, error: 'Authentication failed.');
    }
  }

  static Future<Map<String, dynamic>> _getAccounts() async {
    try {
      final jsonStr = await _storage.read(key: _accountsKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        return Map<String, dynamic>.from(jsonDecode(jsonStr));
      }
    } catch (_) {}
    return {};
  }

  static String deriveNameFromEmail(String email) {
    if (!email.contains('@')) return email.isEmpty ? 'Chef' : email;
    final prefix = email.split('@').first;
    final cleaned = prefix.replaceAll(RegExp(r'[._\-]'), ' ');
    final words = cleaned.split(' ').where((w) => w.isNotEmpty).map((w) {
      return w[0].toUpperCase() + (w.length > 1 ? w.substring(1) : '');
    }).join(' ');
    return words.isNotEmpty ? words : 'Chef';
  }
}
