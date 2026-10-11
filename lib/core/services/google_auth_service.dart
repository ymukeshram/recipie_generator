import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform, debugPrint;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:rasoiai/core/services/user_session.dart';

import 'google_auth_stub.dart'
    if (dart.library.html) 'google_auth_web.dart' as platform_auth;

class GoogleAuthService {
  static const String serverClientId =
      '2574068206-h8e0p4hih8ken82vcija66emko1jm6gn.apps.googleusercontent.com';
  static const String iosClientId =
      '2574068206-1d1ir70tgbd68rk5tfp0frp2epin09pu.apps.googleusercontent.com';

  static const String clientId = serverClientId;

  static VoidCallback? onAuthSuccessCallback;
  static BuildContext? _activeContext;
  static bool _mobileInitialized = false;

  static Future<void> _initMobile() async {
    if (_mobileInitialized) return;
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await GoogleSignIn.instance.initialize(
          clientId: iosClientId,
          serverClientId: serverClientId,
        );
      } else {
        await GoogleSignIn.instance.initialize(
          serverClientId: serverClientId,
        );
      }
      _mobileInitialized = true;
    } catch (e) {
      debugPrint('[GoogleAuthService] GoogleSignIn initialization diagnostic: $e');
    }
  }

  /// Initialize Google Auth listener
  static Future<void> load() async {
    if (kIsWeb) {
      platform_auth.initGoogleAuth(
        onSuccess: (name, email) async {
          final cleanEmail = email.trim();
          if (cleanEmail.isEmpty) return;

          final displayName = name.trim().isNotEmpty
              ? name.trim()
              : UserSession.deriveNameFromEmail(cleanEmail);

          await UserSession.setSession(name: displayName, email: cleanEmail);
          debugPrint('[GoogleAuthService] Web session authenticated for $displayName ($cleanEmail)');

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
      await _initMobile();
    }
  }

  /// Sign out from Google Auth
  static Future<void> signOut() async {
    if (!kIsWeb) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (e) {
        debugPrint('[GoogleAuthService] Sign out diagnostic: $e');
      }
    }
  }

  /// Trigger authentic Google OAuth sign-in flow
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

    // Native Android / iOS authentication flow
    try {
      await _initMobile();

      final GoogleSignInAccount account = await GoogleSignIn.instance.authenticate();
      final verifiedEmail = account.email.trim();

      if (verifiedEmail.isEmpty) {
        throw Exception('No verified email returned from Google.');
      }

      final rawName = account.displayName?.trim() ?? '';
      final displayName = rawName.isNotEmpty
          ? rawName
          : UserSession.deriveNameFromEmail(verifiedEmail);

      // Authenticate only with verified credentials
      await UserSession.setSession(name: displayName, email: verifiedEmail);
      debugPrint('[GoogleAuthService] Verified authentication succeeded for $displayName ($verifiedEmail)');

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
    } on GoogleSignInException catch (e) {
      debugPrint('[GoogleAuthService] GoogleSignInException: code=${e.code}, description=${e.description}');
      if (!context.mounted) return;

      if (e.code == GoogleSignInExceptionCode.canceled) {
        // User actively cancelled or dismissed the account selector
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Google Sign-In was cancelled.'),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Retry',
              textColor: const Color(0xFF81C784),
              onPressed: () => signInWithGoogle(context: context, onSuccess: onSuccess),
            ),
          ),
        );
      } else {
        // Configuration, network, or platform provider issue
        String userFriendlyMessage =
            'Google Sign-In could not be completed. Please ensure your Google account is configured and try again.';

        if (e.code == GoogleSignInExceptionCode.clientConfigurationError ||
            e.code == GoogleSignInExceptionCode.providerConfigurationError) {
          userFriendlyMessage =
              'Google Sign-In configuration error: The application credentials could not be verified by Google Play Services. Please check your network and Google Cloud project configuration.';
        } else if (e.description != null && e.description!.isNotEmpty) {
          userFriendlyMessage = 'Google Sign-In error: ${e.description}';
        }

        _showAuthErrorDialog(
          context: context,
          title: 'Sign-In Failed',
          message: userFriendlyMessage,
          onRetry: () => signInWithGoogle(context: context, onSuccess: onSuccess),
        );
      }
    } catch (e) {
      debugPrint('[GoogleAuthService] Authentication exception: $e');
      if (!context.mounted) return;

      final errStr = e.toString().toLowerCase();
      final bool isCancellation =
          errStr.contains('canceled') || errStr.contains('cancelled') || errStr.contains('12501');

      if (isCancellation) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Google Sign-In was cancelled.'),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Retry',
              textColor: const Color(0xFF81C784),
              onPressed: () => signInWithGoogle(context: context, onSuccess: onSuccess),
            ),
          ),
        );
      } else {
        _showAuthErrorDialog(
          context: context,
          title: 'Authentication Error',
          message:
              'Unable to complete Google authentication. Please verify your connection and try again.',
          onRetry: () => signInWithGoogle(context: context, onSuccess: onSuccess),
        );
      }
    }
  }

  /// Displays an error dialog with a Retry button without bypassing authentication
  static void _showAuthErrorDialog({
    required BuildContext context,
    required String title,
    required String message,
    required VoidCallback onRetry,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 24),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Dismiss'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onRetry();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D6A4F),
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
