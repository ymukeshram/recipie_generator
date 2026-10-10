import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'core/networking/api_client.dart';
import 'core/services/user_session.dart';
import 'core/services/saved_recipes_service.dart';
import 'core/services/history_service.dart';
import 'core/services/theme_service.dart';
import 'core/services/google_auth_service.dart';
import 'core/services/gamification_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Hydrate local services in background with a safety timeout so app boots instantly
  Future.wait([
    ApiClient.loadSavedUrl(),
    UserSession.load(),
    savedRecipesService.init(),
    historyService.init(),
    gamificationService.init(),
    themeService.init(),
    GoogleAuthService.load(),
  ]).timeout(const Duration(milliseconds: 600), onTimeout: () {
    debugPrint('Service hydration timed out; proceeding instantly.');
    return [];
  }).catchError((e) {
    debugPrint('Error during background hydration: $e');
    return [];
  });

  runApp(const ProviderScope(child: RasoiAIApp()));
}

class RasoiAIApp extends StatelessWidget {
  const RasoiAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeService.themeModeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp.router(
          title: 'RasoiAI',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          routerConfig: appRouter,
        );
      },
    );
  }
}
