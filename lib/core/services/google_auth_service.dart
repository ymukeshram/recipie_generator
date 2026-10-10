import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:rasoiai/core/services/user_session.dart';

import 'google_auth_stub.dart'
    if (dart.library.html) 'google_auth_web.dart' as platform_auth;

class GoogleAuthService {
  static const String clientId =
      '2574068206-h8e0p4hih8ken82vcija66emko1jm6gn.apps.googleusercontent.com';

  static VoidCallback? onAuthSuccessCallback;
  static BuildContext? _activeContext;

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
    }
  }

  /// Trigger official Google OAuth sign-in flow
  static Future<void> signInWithGoogle({
    required BuildContext context,
    required VoidCallback onSuccess,
  }) async {
    _activeContext = context;
    onAuthSuccessCallback = onSuccess;

    if (kIsWeb) {
      platform_auth.startGoogleSignIn();
    } else {
      // Demo / non-web fallback
      const demoEmail = 'ymukeshram@gmail.com';
      final demoName = UserSession.deriveNameFromEmail(demoEmail);
      await UserSession.setSession(name: demoName, email: demoEmail);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome, $demoName! Signed in with Google. ✅'),
            backgroundColor: const Color(0xFF1E8E3E),
            behavior: SnackBarBehavior.floating,
          ),
        );
        onSuccess();
      }
    }
  }
}
