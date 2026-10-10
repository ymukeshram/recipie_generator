import 'dart:html' as html;
import 'dart:convert';
import 'package:flutter/foundation.dart';

typedef GoogleAuthSuccessCallback = void Function(String name, String email);

GoogleAuthSuccessCallback? _authCallback;
bool _initialized = false;

void initGoogleAuth({required GoogleAuthSuccessCallback onSuccess}) {
  _authCallback = onSuccess;
  if (_initialized) return;
  _initialized = true;

  html.window.addEventListener('rasoiai_google_auth', (event) {
    try {
      if (event is html.CustomEvent) {
        final detail = event.detail;
        String email = '';
        String name = '';

        if (detail is Map) {
          email = detail['email']?.toString() ?? '';
          name = detail['name']?.toString() ??
              detail['given_name']?.toString() ??
              '';
        } else if (detail != null) {
          final str = detail.toString();
          if (str.startsWith('{')) {
            final decoded = jsonDecode(str);
            if (decoded is Map) {
              email = decoded['email']?.toString() ?? '';
              name = decoded['name']?.toString() ??
                  decoded['given_name']?.toString() ??
                  '';
            }
          }
        }

        if (email.isNotEmpty) {
          if (name.isEmpty) {
            name = email.split('@').first;
          }
          debugPrint('[GoogleAuthWeb] Auth success for: $name ($email)');
          _authCallback?.call(name, email);
        }
      }
    } catch (e) {
      debugPrint('[GoogleAuthWeb] Error handling rasoiai_google_auth event: $e');
    }
  });
}

void startGoogleSignIn() {
  try {
    debugPrint('[GoogleAuthWeb] Dispatching rasoi_request_google_signin event');
    html.window.dispatchEvent(html.CustomEvent('rasoi_request_google_signin'));
  } catch (e) {
    debugPrint('[GoogleAuthWeb] Error dispatching signin request event: $e');
  }
}
