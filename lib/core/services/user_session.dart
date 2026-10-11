import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserSession {
  static const _storage = FlutterSecureStorage();
  static const _isLoggedInKey = 'rasoiai_user_logged_in_state';
  static const _nameKey = 'rasoiai_user_name';
  static const _emailKey = 'rasoiai_user_email';
  static const _accountsKey = 'rasoiai_registered_accounts_v1';

  static bool isLoggedIn = false;
  static final ValueNotifier<bool> authNotifier = ValueNotifier<bool>(false);

  static String userName = '';
  static String userEmail = '';

  /// Hydrate persistent session state from secure storage
  static Future<void> load() async {
    try {
      final savedLoggedIn = await _storage.read(key: _isLoggedInKey);
      final savedName = await _storage.read(key: _nameKey);
      final savedEmail = await _storage.read(key: _emailKey);

      if (savedLoggedIn == 'true' && savedEmail != null && savedEmail.trim().isNotEmpty) {
        isLoggedIn = true;
        userEmail = savedEmail.trim();
        userName = (savedName != null && savedName.trim().isNotEmpty)
            ? savedName.trim()
            : deriveNameFromEmail(userEmail);
      } else {
        isLoggedIn = false;
        userName = '';
        userEmail = '';
      }

      authNotifier.value = isLoggedIn;
    } catch (_) {
      isLoggedIn = false;
      userName = '';
      userEmail = '';
      authNotifier.value = false;
    }
  }

  /// Store a genuine authenticated session
  static Future<void> setSession({required String name, required String email}) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty) return;

    final cleanName = name.trim().isNotEmpty ? name.trim() : deriveNameFromEmail(cleanEmail);

    userName = cleanName;
    userEmail = cleanEmail;
    isLoggedIn = true;
    authNotifier.value = true;

    try {
      await _storage.write(key: _isLoggedInKey, value: 'true');
      await _storage.write(key: _nameKey, value: userName);
      await _storage.write(key: _emailKey, value: userEmail);
    } catch (e) {
      debugPrint('[UserSession] Error writing session to secure storage: $e');
    }
  }

  /// Terminate the active session and remove stored credentials
  static Future<void> clearSession() async {
    isLoggedIn = false;
    userName = '';
    userEmail = '';
    authNotifier.value = false;

    try {
      await _storage.write(key: _isLoggedInKey, value: 'false');
      await _storage.delete(key: _isLoggedInKey);
      await _storage.delete(key: _nameKey);
      await _storage.delete(key: _emailKey);
    } catch (e) {
      debugPrint('[UserSession] Error clearing session from secure storage: $e');
    }
  }

  /// Update the chef's display name
  static Future<void> updateName(String name) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return;
    userName = cleanName;
    try {
      await _storage.write(key: _nameKey, value: userName);
    } catch (_) {}
  }

  /// Register a new user account
  static Future<bool> registerAccount({
    required String name,
    required String email,
    required String password,
    bool googleVerified = true,
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
        'googleVerified': googleVerified,
        'createdAt': DateTime.now().toIso8601String(),
      };
      await _storage.write(key: _accountsKey, value: jsonEncode(accounts));
      await setSession(name: name, email: email);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Check whether an account has been registered
  static Future<bool> isAccountRegistered(String email) async {
    try {
      final accounts = await _getAccounts();
      return accounts.containsKey(email.trim().toLowerCase());
    } catch (_) {
      return false;
    }
  }

  /// Reset password for a registered account
  static Future<bool> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    try {
      final accounts = await _getAccounts();
      final normalizedEmail = email.trim().toLowerCase();
      if (!accounts.containsKey(normalizedEmail)) {
        return false;
      }
      accounts[normalizedEmail]['password'] = newPassword;
      accounts[normalizedEmail]['updatedAt'] = DateTime.now().toIso8601String();
      await _storage.write(key: _accountsKey, value: jsonEncode(accounts));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Validate user credentials on login against registered accounts
  static Future<({bool isValid, String? name, String? error})> validateCredentials({
    required String email,
    required String password,
  }) async {
    try {
      final accounts = await _getAccounts();
      final normalizedEmail = email.trim().toLowerCase();

      if (accounts.isEmpty) {
        return (
          isValid: false,
          name: null,
          error: 'No registered account found. Please Sign Up to verify your Google account first.',
        );
      }

      final user = accounts[normalizedEmail];
      if (user == null) {
        return (
          isValid: false,
          name: null,
          error: 'Account not found. Please Sign Up to verify your Google account first.',
        );
      }

      if (user['password'] != password) {
        return (
          isValid: false,
          name: null,
          error: 'Incorrect password. Please try again or use Forgot Password.',
        );
      }

      final registeredName = user['name'] as String?;
      return (isValid: true, name: registeredName, error: null);
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
