import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rasoiai/features/onboarding/onboarding_screen.dart';
import 'package:rasoiai/features/auth/presentation/login_screen.dart';
import 'package:rasoiai/features/auth/presentation/signup_screen.dart';
import 'package:rasoiai/features/auth/presentation/forgot_password_screen.dart';
import 'package:rasoiai/features/home/presentation/main_scaffold.dart';
import 'package:rasoiai/features/home/presentation/home_screen.dart';
import 'package:rasoiai/features/explore/presentation/explore_screen.dart';
import 'package:rasoiai/features/recipe_generation/presentation/recipe_generation_screen.dart';
import 'package:rasoiai/features/recipe_generation/presentation/photo_recipe_generation_screen.dart';
import 'package:rasoiai/features/recipe_details/presentation/recipe_details_screen.dart';
import 'package:rasoiai/features/recipe_customization/presentation/recipe_customization_screen.dart';
import 'package:rasoiai/features/saved_recipes/presentation/saved_recipes_screen.dart';
import 'package:rasoiai/features/history/presentation/history_screen.dart';
import 'package:rasoiai/features/profile/presentation/profile_screen.dart';
import 'package:rasoiai/core/theme/app_colors.dart';
import 'package:rasoiai/core/theme/app_theme.dart';
import 'package:rasoiai/shared/models/recipe.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Ensures landing, login, and signup pages always render in clean light mode
class ForceLightScope extends StatelessWidget {
  final Widget child;
  const ForceLightScope({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.lightTheme,
      child: child,
    );
  }
}

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/onboarding',
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const ForceLightScope(child: OnboardingScreen()),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const ForceLightScope(child: LoginScreen()),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const ForceLightScope(child: SignupScreen()),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForceLightScope(child: ForgotPasswordScreen()),
    ),

    // Shell Route with persistent Bottom Navigation
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => MainScaffold(child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/explore',
          builder: (context, state) => const ExploreScreen(),
        ),
        GoRoute(
          path: '/generate',
          builder: (context, state) => const RecipeGenerationScreen(),
        ),
        GoRoute(
          path: '/generate/photo',
          builder: (context, state) => const PhotoRecipeGenerationScreen(),
        ),
        GoRoute(
          path: '/recipe/:id',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            final extra = state.extra as Recipe?;
            return RecipeDetailsScreen(recipeId: id, recipeExtra: extra);
          },
        ),
        GoRoute(
          path: '/recipe/:id/customize',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            final extra = state.extra as Recipe?;
            return RecipeCustomizationScreen(recipeId: id, recipeExtra: extra);
          },
        ),
        GoRoute(
          path: '/saved',
          builder: (context, state) => const SavedRecipesScreen(),
        ),
        GoRoute(
          path: '/history',
          builder: (context, state) => const HistoryScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
  ],
);
