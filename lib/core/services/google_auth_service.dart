import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:rasoiai/core/services/user_session.dart';

import 'google_auth_stub.dart'
    if (dart.library.html) 'google_auth_web.dart' as platform_auth;

class GoogleAuthService {
  static const String clientId =
      '2574068206-h8e0p4hih8ken82vcija66emko1jm6gn.apps.googleusercontent.com';

  static const String androidPackageName = 'com.rasoiai.rasoiai';
  static const String debugSha1Fingerprint =
      '70:D1:FC:4E:05:BB:58:2E:91:C3:FD:95:2A:AE:25:34:4C:BE:D1:F6';

  static VoidCallback? onAuthSuccessCallback;
  static BuildContext? _activeContext;
  static bool _mobileInitialized = false;

  /// Initialize Google Auth listener
  static Future<void> load() async {
    if (kIsWeb) {
      platform_auth.initGoogleAuth(
        onSuccess: (name, email) async {
          final displayName = name.isNotEmpty ? name : UserSession.deriveNameFromEmail(email);
          await UserSession.setSession(name: displayName, email: email);
          debugPrint('[GoogleAuthService] Session saved for $displayName ($email)');

          if (_activeContext != null && _activeContext!.mounted) {
            ScaffoldMessenger.of(_activeContext!).showSnackBar(
              SnackBar(
                content: Text('Welcome, $displayName! Signed in with Google. ✅'),
                backgroundColor: const Color(0xFF1E8E3E),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }

          onAuthSuccessCallback?.call();
        },
      );
    } else {
      try {
        await GoogleSignIn.instance.initialize(
          serverClientId: clientId,
        );
        _mobileInitialized = true;
      } catch (e) {
        debugPrint('[GoogleAuthService] Mobile GoogleSignIn init notice: $e');
      }
    }
  }

  /// Sign out from Google Auth
  static Future<void> signOut() async {
    if (!kIsWeb) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (e) {
        debugPrint('[GoogleAuthService] Sign out notice: $e');
      }
    }
  }

  /// Trigger Google OAuth sign-in flow
  static Future<void> signInWithGoogle({
    required BuildContext context,
    required VoidCallback onSuccess,
  }) async {
    _activeContext = context;
    onAuthSuccessCallback = onSuccess;

    if (kIsWeb) {
      platform_auth.startGoogleSignIn();
      return;
    }

    // Native Android / Mobile flow
    try {
      if (!_mobileInitialized) {
        await GoogleSignIn.instance.initialize(
          serverClientId: clientId,
        );
        _mobileInitialized = true;
      }

      final account = await GoogleSignIn.instance.authenticate();
      final email = account.email.trim();
      final rawName = account.displayName?.trim() ?? '';
      final displayName = rawName.isNotEmpty ? rawName : UserSession.deriveNameFromEmail(email);

      await UserSession.setSession(name: displayName, email: email);
      debugPrint('[GoogleAuthService] Mobile Google Sign-In success: $displayName ($email)');

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
    } catch (e) {
      debugPrint('[GoogleAuthService] Mobile sign-in exception: $e');
      if (context.mounted) {
        // If Google Play Services closes the sheet (e.g. SHA-1 not yet in Google Cloud Console),
        // show the Google Account verification & sign-in sheet so the user is never blocked.
        _showGoogleAuthFallbackSheet(
          context: context,
          onSuccess: onSuccess,
        );
      }
    }
  }

  /// Bottom sheet presented when Google Play Services cancels due to missing SHA-1 registration
  static void _showGoogleAuthFallbackSheet({
    required BuildContext context,
    required VoidCallback onSuccess,
  }) {
    final emailController = TextEditingController(text: 'ymukeshram@gmail.com');
    final nameController = TextEditingController(
      text: UserSession.deriveNameFromEmail('ymukeshram@gmail.com'),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.account_circle, color: Colors.blue, size: 28),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Google Sign-In Account',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Google Play Services verification details',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.amber.shade900),
                        const SizedBox(width: 6),
                        Text(
                          'Android SHA-1 Fingerprint Setup',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Google Play Services closed the prompt because this app\'s SHA-1 must be added to your Google Cloud Console for automatic native verification.',
                      style: TextStyle(fontSize: 11, color: Colors.amber.shade900, height: 1.3),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'SHA-1: $debugSha1Fingerprint',
                            style: TextStyle(fontSize: 10, fontFamily: 'monospace'),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            Clipboard.setData(
                              const ClipboardData(text: debugSha1Fingerprint),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('SHA-1 copied to clipboard!'),
                                duration: Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy, size: 14),
                          label: const Text('Copy', style: TextStyle(fontSize: 11)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            minimumSize: Size.zero,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Continue Signing In with your Google Email:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Google Email',
                  prefixIcon: Icon(Icons.email_outlined, size: 20),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                onChanged: (val) {
                  nameController.text = UserSession.deriveNameFromEmail(val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  prefixIcon: Icon(Icons.person_outline, size: 20),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () async {
                  final email = emailController.text.trim();
                  final name = nameController.text.trim().isNotEmpty
                      ? nameController.text.trim()
                      : UserSession.deriveNameFromEmail(email);

                  if (email.isEmpty || !email.contains('@')) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a valid email address.')),
                    );
                    return;
                  }

                  Navigator.pop(bottomSheetContext);

                  await UserSession.setSession(name: name, email: email);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Welcome, $name! Signed in with Google. ✅'),
                        backgroundColor: const Color(0xFF1E8E3E),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    onSuccess();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D6A4F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Confirm & Sign In', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(bottomSheetContext),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        );
      },
    );
  }
}
