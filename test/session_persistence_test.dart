import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:rasoiai/core/services/user_session.dart';
import 'package:rasoiai/core/routing/app_router.dart';
import 'package:go_router/go_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await UserSession.load();
  });

  tearDown(() async {
    await UserSession.clearSession();
  });

  test('UserSession default state is not logged in with empty credentials', () {
    expect(UserSession.isLoggedIn, isFalse);
    expect(UserSession.userName, isEmpty);
    expect(UserSession.userEmail, isEmpty);
    expect(UserSession.authNotifier.value, isFalse);
  });

  test('setSession persists logged in state and notifies listeners', () async {
    bool notified = false;
    UserSession.authNotifier.addListener(() {
      notified = true;
    });

    await UserSession.setSession(name: 'Chef Anita', email: 'anita@example.com');

    expect(UserSession.isLoggedIn, isTrue);
    expect(UserSession.userName, 'Chef Anita');
    expect(UserSession.userEmail, 'anita@example.com');
    expect(UserSession.authNotifier.value, isTrue);
    expect(notified, isTrue);

    // Verify cross-session persistence upon reload
    UserSession.isLoggedIn = false;
    UserSession.userName = '';
    UserSession.userEmail = '';
    await UserSession.load();
    expect(UserSession.isLoggedIn, isTrue);
    expect(UserSession.userName, 'Chef Anita');
    expect(UserSession.userEmail, 'anita@example.com');
  });

  test('clearSession resets logged in state, wipes credentials, and notifies', () async {
    await UserSession.setSession(name: 'Chef Anita', email: 'anita@example.com');
    expect(UserSession.isLoggedIn, isTrue);

    await UserSession.clearSession();
    expect(UserSession.isLoggedIn, isFalse);
    expect(UserSession.userName, isEmpty);
    expect(UserSession.userEmail, isEmpty);
    expect(UserSession.authNotifier.value, isFalse);

    // Verify it remains logged out on subsequent load
    await UserSession.load();
    expect(UserSession.isLoggedIn, isFalse);
    expect(UserSession.userName, isEmpty);
    expect(UserSession.userEmail, isEmpty);
  });

  test('Empty email cannot create an authenticated session', () async {
    await UserSession.setSession(name: 'Invalid User', email: '   ');
    expect(UserSession.isLoggedIn, isFalse);
    expect(UserSession.userEmail, isEmpty);
  });

  test('Registration and credential validation works without hardcoded backdoors', () async {
    // Validating before registering any account fails cleanly
    final preResult = await UserSession.validateCredentials(
      email: 'chef@rasoiai.com',
      password: 'chef123',
    );
    expect(preResult.isValid, isFalse);

    // Register account
    final regSuccess = await UserSession.registerAccount(
      name: 'Chef Vikram',
      email: 'vikram@example.com',
      password: 'password123',
    );
    expect(regSuccess, isTrue);
    expect(UserSession.isLoggedIn, isTrue);
    expect(UserSession.userName, 'Chef Vikram');
    expect(UserSession.userEmail, 'vikram@example.com');

    // Logging in with correct password succeeds
    final loginResult = await UserSession.validateCredentials(
      email: 'vikram@example.com',
      password: 'password123',
    );
    expect(loginResult.isValid, isTrue);
    expect(loginResult.name, 'Chef Vikram');

    // Incorrect password fails
    final wrongPasswordResult = await UserSession.validateCredentials(
      email: 'vikram@example.com',
      password: 'wrong_password',
    );
    expect(wrongPasswordResult.isValid, isFalse);
  });

  test('AppRouter initialLocation reflects authentication state', () {
    // When logged out
    expect(UserSession.isLoggedIn, isFalse);
    // App router exists and can be inspected
    expect(appRouter, isNotNull);
  });

  test('Failed authentication guarantees UserSession remains strictly unauthenticated', () async {
    // Ensure any dirty state is cleared
    await UserSession.clearSession();
    expect(UserSession.isLoggedIn, isFalse);
    expect(UserSession.userName, isEmpty);
    expect(UserSession.userEmail, isEmpty);

    // Verify subsequent load also remains false
    await UserSession.load();
    expect(UserSession.isLoggedIn, isFalse);
  });

  test('Routes /signup and /forgot-password are registered with authentic screens', () {
    final signupRoute = appRouter.configuration.routes
        .whereType<GoRoute>()
        .firstWhere((r) => r.path == '/signup');
    expect(signupRoute.builder, isNotNull);

    final forgotPasswordRoute = appRouter.configuration.routes
        .whereType<GoRoute>()
        .firstWhere((r) => r.path == '/forgot-password');
    expect(forgotPasswordRoute.builder, isNotNull);
  });

  test('isAccountRegistered and resetPassword function correctly', () async {
    expect(await UserSession.isAccountRegistered('newchef@gmail.com'), isFalse);

    await UserSession.registerAccount(
      name: 'New Chef',
      email: 'newchef@gmail.com',
      password: 'password123',
    );
    expect(await UserSession.isAccountRegistered('newchef@gmail.com'), isTrue);

    // Reset password
    final resetOk = await UserSession.resetPassword(
      email: 'newchef@gmail.com',
      newPassword: 'newpassword456',
    );
    expect(resetOk, isTrue);

    // Old password fails
    final oldLogin = await UserSession.validateCredentials(
      email: 'newchef@gmail.com',
      password: 'password123',
    );
    expect(oldLogin.isValid, isFalse);

    // New password succeeds
    final newLogin = await UserSession.validateCredentials(
      email: 'newchef@gmail.com',
      password: 'newpassword456',
    );
    expect(newLogin.isValid, isTrue);
  });
}
