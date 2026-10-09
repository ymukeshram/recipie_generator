import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserSession {
  static const _storage = FlutterSecureStorage();
  static const _nameKey = 'rasoiai_user_name';
  static const _emailKey = 'rasoiai_user_email';

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
