typedef GoogleAuthSuccessCallback = void Function(String name, String email);

void initGoogleAuth({required GoogleAuthSuccessCallback onSuccess}) {
  // No-op on non-web platforms (e.g. unit tests running on Dart VM)
}

void startGoogleSignIn() {
  // No-op on non-web platforms
}
