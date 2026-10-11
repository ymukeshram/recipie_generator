import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:rasoiai/core/services/user_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await UserSession.load();
  });

  tearDown(() async {
    await UserSession.clearSession();
  });

  test('UserSession default state is not logged in', () {
    expect(UserSession.isLoggedIn, isFalse);
    expect(UserSession.authNotifier.value, isFalse);
  });

  test('setSession persists logged in state and notifies listeners', () async {
    bool notified = false;
    UserSession.authNotifier.addListener(() {
      notified = true;
    });

    await UserSession.setSession(name: 'Mukesh Ram', email: 'mukesh@example.com');

    expect(UserSession.isLoggedIn, isTrue);
    expect(UserSession.userName, 'Mukesh Ram');
    expect(UserSession.userEmail, 'mukesh@example.com');
    expect(UserSession.authNotifier.value, isTrue);
    expect(notified, isTrue);

    // Reload from storage to verify cross-session persistence
    UserSession.isLoggedIn = false;
    await UserSession.load();
    expect(UserSession.isLoggedIn, isTrue);
    expect(UserSession.userName, 'Mukesh Ram');
    expect(UserSession.userEmail, 'mukesh@example.com');
  });

  test('clearSession resets logged in state and deletes credentials', () async {
    await UserSession.setSession(name: 'Mukesh Ram', email: 'mukesh@example.com');
    expect(UserSession.isLoggedIn, isTrue);

    await UserSession.clearSession();
    expect(UserSession.isLoggedIn, isFalse);
    expect(UserSession.authNotifier.value, isFalse);

    // Reload from storage to verify it persists as logged out
    await UserSession.load();
    expect(UserSession.isLoggedIn, isFalse);
  });
}
