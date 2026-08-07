// Widget tests for Lab Activity 1 - Ephemeral vs. App State.
//
// These tests prove the core claim of the activity: the setState counter is
// destroyed when its screen is rebuilt, while the Provider counter is not.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:fuertes_advmobprog/main.dart';

/// Builds the app under test with fresh providers, mirroring main().
Widget buildTestApp() {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => CounterProvider()),
    ],
    child: const FuertesAdvMobProg(),
  );
}

void main() {
  testWidgets('both counters start at 0', (tester) async {
    await tester.pumpWidget(buildTestApp());

    // Two cards, both showing zero.
    expect(find.text('Ephemeral State'), findsOneWidget);
    expect(find.text('App State'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(2));
  });

  testWidgets('increment raises both counters together', (tester) async {
    await tester.pumpWidget(buildTestApp());

    // Tap the single Increment button three times.
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Increment'));
      await tester.pump();
    }

    // Both counters read 3, so they are in sync while the screen is alive.
    expect(find.text('3'), findsNWidgets(2));
  });

  testWidgets(
      'rebuilding the screen resets ephemeral state but keeps app state',
      (tester) async {
    await tester.pumpWidget(buildTestApp());

    // Raise both counters to 4.
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('Increment'));
      await tester.pump();
    }
    expect(find.text('4'), findsNWidgets(2));

    // Replace the screen with a new instance, disposing the old State object.
    await tester.tap(find.text('Rebuild this screen'));
    await tester.pumpAndSettle();

    // THE POINT OF THE ACTIVITY:
    // ephemeral went back to 0, app state is still 4.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('app state counter is readable from the settings screen',
      (tester) async {
    await tester.pumpWidget(buildTestApp());

    await tester.tap(find.text('Increment'));
    await tester.tap(find.text('Increment'));
    await tester.pump();

    // Navigate to screen 2.
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    // The same value is visible on a different screen.
    expect(find.text('App state counter'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('toggling the switch flips the whole app to dark mode',
      (tester) async {
    await tester.pumpWidget(buildTestApp());

    // Light mode to begin with.
    expect(
      Theme.of(tester.element(find.text('Counter'))).brightness,
      Brightness.light,
    );

    // Go to the settings screen and flip the switch.
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    expect(find.text('Light Mode ON'), findsOneWidget);

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    // The label updated and the theme really is dark now.
    expect(find.text('Dark Mode ON'), findsOneWidget);
    expect(
      Theme.of(tester.element(find.text('Dark Mode ON'))).brightness,
      Brightness.dark,
    );
  });
}
