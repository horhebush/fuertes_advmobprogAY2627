import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:fuertes_advmobprog/main.dart';

Widget testApp() {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeModel()),
      ChangeNotifierProvider(create: (_) => CounterModel()),
    ],
    child: const FuertesAdvMobProg(),
  );
}

// The buttons sit below the fold on the small test screen, so scroll to them
// before tapping.
Future<void> tapButton(WidgetTester tester, String label) async {
  final finder = find.text(label);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('increment raises both counters', (tester) async {
    await tester.pumpWidget(testApp());
    expect(find.text('0'), findsNWidgets(2));

    for (var i = 0; i < 3; i++) {
      await tapButton(tester, 'Increment');
    }
    expect(find.text('3'), findsNWidgets(2));
  });

  testWidgets('rebuilding the screen resets only the ephemeral counter',
      (tester) async {
    await tester.pumpWidget(testApp());
    for (var i = 0; i < 4; i++) {
      await tapButton(tester, 'Increment');
    }

    await tapButton(tester, 'Rebuild this screen');

    expect(find.text('0'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('the switch changes the theme', (tester) async {
    await tester.pumpWidget(testApp());
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    expect(find.text('Light Mode ON'), findsOneWidget);

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    expect(find.text('Dark Mode ON'), findsOneWidget);
    expect(
      Theme.of(tester.element(find.text('Dark Mode ON'))).brightness,
      Brightness.dark,
    );
  });
}
