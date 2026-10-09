import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rasoiai/main.dart';

void main() {
  testWidgets('App builds and loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: RasoiAIApp()));
    expect(find.text('Next'), findsOneWidget);
  });
}
