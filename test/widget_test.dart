import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rasoiai/main.dart';
import 'package:rasoiai/core/services/gamification_service.dart';
import 'package:rasoiai/features/recipe_generation/presentation/recipe_generation_screen.dart';
import 'package:rasoiai/features/home/presentation/widgets/surprise_me_card.dart';
import 'package:rasoiai/features/profile/presentation/widgets/gamification_widgets.dart';

void main() {
  testWidgets('App builds and loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: RasoiAIApp()));
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('RecipeGenerationScreen renders without RenderFlex overflow on small screen widths', (WidgetTester tester) async {
    // Test on a small Android screen (320px width - e.g. small budget Android phone)
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: RecipeGenerationScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Parameters & Indian Preferences'), findsOneWidget);
    expect(find.text('Regional Cuisine'), findsOneWidget);
    expect(find.text('Meal Category'), findsOneWidget);
  });

  testWidgets('RecipeGenerationScreen renders without overflow on 360px standard width', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: RecipeGenerationScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Regional Cuisine'), findsOneWidget);
  });

  testWidgets('SurpriseMeCard renders and shows SPIN THE WHEEL button', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SurpriseMeCard(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SURPRISE ME!'), findsOneWidget);
    expect(find.text('SPIN THE WHEEL'), findsOneWidget);
  });

  testWidgets('Profile Gamification widgets render correctly', (WidgetTester tester) async {
    final mockState = gamificationService.stateNotifier.value ?? GamificationState.initial();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                CookingStreakCard(state: mockState),
                const SizedBox(height: 16),
                DailyChallengeCard(
                  challenge: mockState.dailyChallenge,
                  onAccept: () {},
                ),
                const SizedBox(height: 16),
                BadgesGridSection(badges: mockState.badges),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Streak'), findsWidgets);
    expect(find.text(mockState.dailyChallenge.title), findsOneWidget);
    expect(find.textContaining('Achievement Badges'), findsOneWidget);
  });
}
