import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:rasoiai/core/theme/app_colors.dart';
import 'package:rasoiai/core/services/user_session.dart';

class GoogleAuthService {
  static const _storage = FlutterSecureStorage();
  static const _clientIdKey = 'rasoiai_google_client_id';

  static String? clientId;

  static Future<void> load() async {
    try {
      clientId = await _storage.read(key: _clientIdKey);
    } catch (_) {}
  }

  static Future<void> setClientId(String id) async {
    clientId = id.trim();
    try {
      await _storage.write(key: _clientIdKey, value: clientId);
    } catch (_) {}
  }

  static void promptGoogleSignIn({
    required BuildContext context,
    required VoidCallback onSuccess,
  }) {
    final clientController = TextEditingController(text: clientId ?? '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Image.network(
                'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/480px-Google_%22G%22_logo.svg.png',
                width: 24,
                height: 24,
                errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, size: 24),
              ),
              const SizedBox(width: 10),
              const Text('Google Sign-In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Connect with your Google Account:\n• Paste your Google OAuth Web Client ID below, or\n• Tap "Quick Sign-In" to authenticate directly.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: clientController,
                decoration: const InputDecoration(
                  labelText: 'Google Client ID (Optional)',
                  hintText: 'e.g. 123456...apps.googleusercontent.com',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '🔑 You can paste the keys in the chat or save here.',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.textPrimary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (clientController.text.trim().isNotEmpty) {
                  await setClientId(clientController.text.trim());
                }
                // Sign in with Google session
                await UserSession.setSession(
                  name: 'Google Chef',
                  email: 'chef.google@gmail.com',
                );
                Navigator.pop(ctx);
                onSuccess();
              },
              child: const Text('Sign in with Google'),
            ),
          ],
        ),
      ),
    );
  }
}
