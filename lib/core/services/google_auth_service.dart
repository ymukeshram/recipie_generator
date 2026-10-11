import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:rasoiai/core/services/user_session.dart';

import 'google_auth_stub.dart'
    if (dart.library.html) 'google_auth_web.dart' as platform_auth;

class GoogleAuthService {
  static const String clientId =
      '2574068206-h8e0p4hih8ken82vcija66emko1jm6gn.apps.googleusercontent.com';

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

  /// Trigger official Google OAuth sign-in flow
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

    // Genuine Native Android / Mobile flow
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
        final errString = e.toString();
        if (errString.contains('canceled') ||
            errString.contains('cancelled') ||
            errString.contains('SIGN_IN_CANCELLED')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Google Sign-In was cancelled.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Google Sign-In failed: $errString'),
              backgroundColor: const Color(0xFFDC2626),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }
}
