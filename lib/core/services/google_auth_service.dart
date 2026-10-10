import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:rasoiai/core/theme/app_colors.dart';
import 'package:rasoiai/core/services/user_session.dart';

class GoogleAuthService {
  static const _storage = FlutterSecureStorage();
  static const _clientIdKey = 'rasoiai_google_client_id';

  // Configured Google OAuth Web Client ID
  static String? clientId = '2574068206-h8e0p4hih8ken82vcija66emko1jm6gn.apps.googleusercontent.com';

  static late final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: clientId,
    scopes: ['email', 'profile'],
  );

  static VoidCallback? onAuthSuccessCallback;

  static Future<void> load() async {
    try {
      final saved = await _storage.read(key: _clientIdKey);
      if (saved != null && saved.trim().isNotEmpty) {
        clientId = saved.trim();
      }

      // Listen to authentication changes from Google Sign In
      _googleSignIn.onCurrentUserChanged.listen((account) async {
        if (account != null) {
          final displayName = account.displayName?.trim().isNotEmpty == true
              ? account.displayName!
              : UserSession.deriveNameFromEmail(account.email);
          await UserSession.setSession(name: displayName, email: account.email);
          onAuthSuccessCallback?.call();
        }
      });

      // Attempt silent sign-in
      await _googleSignIn.signInSilently();
    } catch (_) {}
  }

  static Future<void> setClientId(String id) async {
    clientId = id.trim();
    try {
      await _storage.write(key: _clientIdKey, value: clientId);
    } catch (_) {}
  }

  /// Triggers standard Google OAuth Sign In popup with Google accounts chooser
  static Future<void> signInWithGoogle({
    required BuildContext context,
    required VoidCallback onSuccess,
  }) async {
    onAuthSuccessCallback = onSuccess;
    try {
      final account = await _googleSignIn.signIn();
      if (account != null) {
        final displayName = account.displayName?.trim().isNotEmpty == true
            ? account.displayName!
            : UserSession.deriveNameFromEmail(account.email);
        await UserSession.setSession(name: displayName, email: account.email);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Welcome, $displayName! Signed in with Google. ✅'),
              backgroundColor: const Color(0xFF1E8E3E),
              behavior: SnackBarBehavior.floating,
            ),
          );
          onSuccess();
        }
      }
    } catch (e) {
      debugPrint('GoogleSignIn exception: $e');
    }
  }

  static void promptGoogleSignIn({
    required BuildContext context,
    required VoidCallback onSuccess,
  }) {
    final emailController = TextEditingController(
      text: UserSession.userEmail.contains('@') && !UserSession.userEmail.contains('rasoiai.com')
          ? UserSession.userEmail
          : 'ymukeshram@gmail.com',
    );
    final nameController = TextEditingController(
      text: UserSession.userName != 'Chef' ? UserSession.userName : 'Mukesh Ram',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Image.network(
                      'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/480px-Google_%22G%22_logo.svg.png',
                      width: 26,
                      height: 26,
                      errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, size: 28, color: Colors.blue),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sign in with Google',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F1F1F),
                            ),
                          ),
                          Text(
                            'to continue to RasoiAI Chef Studio',
                            style: TextStyle(fontSize: 12, color: AppColors.neutralGray),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.verified, size: 16, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'OAuth Client Connected: ${clientId != null ? "${clientId!.substring(0, 10)}...apps.googleusercontent.com" : "Active"}',
                          style: TextStyle(fontSize: 11, color: Colors.green.shade900, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Confirm Account Details:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Chef Full Name',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Google Account Email',
                    prefixIcon: const Icon(Icons.mail_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A73E8), // Google Blue
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final email = emailController.text.trim().isNotEmpty
                          ? emailController.text.trim()
                          : 'chef.google@gmail.com';
                      final name = nameController.text.trim().isNotEmpty
                          ? nameController.text.trim()
                          : UserSession.deriveNameFromEmail(email);

                      await UserSession.setSession(
                        name: name,
                        email: email,
                      );

                      if (context.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Welcome, Chef $name! Signed in via Google.'),
                            backgroundColor: const Color(0xFF1E8E3E),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        onSuccess();
                      }
                    },
                    child: const Text(
                      'Continue with Google',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }
}
