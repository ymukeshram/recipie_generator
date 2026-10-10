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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiClient.loadSavedUrl();
  await UserSession.load();
  await savedRecipesService.init();
  await historyService.init();
  await gamificationService.init();
  await themeService.init();
  await GoogleAuthService.load();
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
