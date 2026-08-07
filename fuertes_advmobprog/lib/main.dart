// =============================================================================
// Lab Activity 1 - Ephemeral vs. App State
// Jorge Fuertes | INF231
//
// This app demonstrates the two kinds of state in Flutter side by side:
//
//   Ephemeral (local) state -> managed with setState() inside a StatefulWidget.
//                              Short-lived. Only the widget that owns it cares
//                              about it, and it is lost when that widget is
//                              disposed (e.g. navigating away and back).
//
//   App state               -> managed with Provider + ChangeNotifier.
//                              Long-lived. Lives above the widget tree, so it
//                              survives navigation and can be read or changed
//                              from any screen in the app.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Entry point of the application.
///
/// The two ChangeNotifier providers are registered ABOVE MaterialApp using a
/// MultiProvider. Registering them here (rather than inside a screen) is what
/// makes their data app state: because they sit above the Navigator, pushing
/// and popping screens never destroys them.
void main() {
  runApp(
    MultiProvider(
      providers: [
        // Holds the light/dark preference for the whole app.
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        // Holds the app-state counter that survives navigation.
        ChangeNotifierProvider(create: (_) => CounterProvider()),
      ],
      child: const FuertesAdvMobProg(),
    ),
  );
}

// =============================================================================
// APP STATE
// =============================================================================

/// App state #1: the theme preference.
///
/// Mixing in [ChangeNotifier] gives this plain Dart class the ability to tell
/// listening widgets "my data changed, please rebuild" via notifyListeners().
class ThemeProvider with ChangeNotifier {
  // Private so no outside code can change it without going through
  // toggleTheme(), which guarantees listeners are always notified.
  bool _isDark = false;

  /// Read-only view of the current mode, exposed to the UI.
  bool get isDark => _isDark;

  /// Flips between light and dark mode, then rebuilds every listening widget.
  ///
  /// Called from the switch on the Theme Settings screen. Because the theme is
  /// app state, one tap here restyles every screen in the app at once.
  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }
}

/// App state #2: a counter that deliberately contrasts with the ephemeral one.
///
/// This is the same idea as the setState counter on the home screen, but the
/// value is stored here instead of inside the widget. That single difference is
/// what makes it survive navigation - proving the ephemeral vs app state point.
class CounterProvider with ChangeNotifier {
  int _count = 0;

  /// Read-only view of the persisted count.
  int get count => _count;

  /// Adds one to the app-state counter and rebuilds anything watching it.
  void increment() {
    _count++;
    notifyListeners();
  }

  /// Returns the app-state counter to zero.
  void reset() {
    _count = 0;
    notifyListeners();
  }
}

// =============================================================================
// ROOT WIDGET
// =============================================================================

/// Root widget of the app.
///
/// Stateless because it owns no data of its own - it only reads the app state
/// from ThemeProvider to decide which ThemeData to hand to MaterialApp.
class FuertesAdvMobProg extends StatelessWidget {
  const FuertesAdvMobProg({super.key});

  @override
  Widget build(BuildContext context) {
    // context.watch<T>() subscribes this widget to the provider, so the whole
    // MaterialApp rebuilds (and restyles) the moment the theme is toggled.
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'Ephemeral vs App State',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      // Driven entirely by app state.
      themeMode: themeProvider.isDark ? ThemeMode.dark : ThemeMode.light,
      home: const CounterScreen(),
    );
  }
}

// =============================================================================
// SCREEN 1 - COUNTER
// =============================================================================

/// Screen 1 of 2: the counter screen.
///
/// StatefulWidget because it owns the ephemeral counter. A StatelessWidget
/// cannot hold changing data, so setState() would not be available.
class CounterScreen extends StatefulWidget {
  const CounterScreen({super.key});

  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen> {
  /// EPHEMERAL STATE.
  ///
  /// Lives in the State object of this one screen. Nothing else in the app can
  /// see it, and it resets to 0 whenever this screen is rebuilt from scratch.
  int _ephemeralCount = 0;

  /// Increments the ephemeral counter.
  ///
  /// setState() marks this widget dirty so Flutter re-runs build() with the new
  /// value. Note it only rebuilds THIS widget - not the rest of the app.
  void _incrementEphemeral() {
    setState(() {
      _ephemeralCount++;
    });
  }

  /// Resets only the ephemeral counter back to zero.
  void _resetEphemeral() {
    setState(() {
      _ephemeralCount = 0;
    });
  }

  /// Navigates to Screen 2, where the dark/light switch lives.
  ///
  /// Pushing a route does NOT destroy this screen, so the ephemeral counter is
  /// still here on return. Use the "Replace screen" button to see it reset.
  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  /// Replaces this screen with a brand new instance of itself.
  ///
  /// This is the clearest demonstration of the difference: the old State object
  /// is disposed, so _ephemeralCount is destroyed and starts again at 0, while
  /// the Provider-backed counter above the Navigator keeps its value.
  void _replaceScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const CounterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Read the app-state counter. watch() so this screen rebuilds when it
    // changes, even if the change came from somewhere else in the app.
    final counterProvider = context.watch<CounterProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Counter'),
        actions: [
          // Opens Screen 2 (the theme toggle screen).
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Theme Settings',
            onPressed: _openSettings,
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ---------------------------------------------------------------
              // Card A - the ephemeral counter
              // ---------------------------------------------------------------
              _CounterCard(
                label: 'Ephemeral State',
                helper: 'setState() - resets when this screen is rebuilt',
                value: _ephemeralCount,
                accent: Theme.of(context).colorScheme.primary,
                onReset: _resetEphemeral,
              ),
              const SizedBox(height: 16),

              // ---------------------------------------------------------------
              // Card B - the app-state counter
              // ---------------------------------------------------------------
              _CounterCard(
                label: 'App State',
                helper: 'Provider - survives navigation and screen rebuilds',
                value: counterProvider.count,
                accent: Theme.of(context).colorScheme.tertiary,
                onReset: counterProvider.reset,
              ),
              const SizedBox(height: 24),

              // Rebuilds this screen from scratch to prove the difference.
              OutlinedButton.icon(
                onPressed: _replaceScreen,
                icon: const Icon(Icons.refresh),
                label: const Text('Rebuild this screen'),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap + a few times, then rebuild.\n'
                'Ephemeral goes back to 0. App state does not.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
      // One button raises BOTH counters, so the only reason their values ever
      // diverge is where each one is stored.
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _incrementEphemeral(); // ephemeral, via setState
          counterProvider.increment(); // app state, via ChangeNotifier
        },
        tooltip: 'Increment both counters',
        icon: const Icon(Icons.add),
        label: const Text('Increment'),
      ),
    );
  }
}

/// A small reusable card that displays one counter.
///
/// Pulled out into its own widget so the two counters are guaranteed to be
/// presented identically - the only visible difference is the number itself.
class _CounterCard extends StatelessWidget {
  const _CounterCard({
    required this.label,
    required this.helper,
    required this.value,
    required this.accent,
    required this.onReset,
  });

  /// Heading shown on the card, e.g. "Ephemeral State".
  final String label;

  /// One-line explanation of how this counter is managed.
  final String helper;

  /// The number to display.
  final int value;

  /// Colour used for the heading and the big number.
  final Color accent;

  /// Called when the card's reset button is tapped.
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Container(
        width: 320,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Expanded so a long heading yields space to the reset button
                // instead of overflowing the row on narrow screens.
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                // Resets just this one counter.
                IconButton(
                  icon: const Icon(Icons.restart_alt, size: 20),
                  tooltip: 'Reset $label',
                  onPressed: onReset,
                ),
              ],
            ),
            Text(helper, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            Center(
              child: Text(
                '$value',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// SCREEN 2 - THEME SETTINGS
// =============================================================================

/// Screen 2 of 2: the theme toggle screen.
///
/// Stateless even though it contains a Switch. The switch's value is app state
/// owned by ThemeProvider, so this widget has no local data to track - it just
/// reads the provider and calls a method on it.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Subscribe so the switch and label update the instant the theme flips.
    final themeProvider = context.watch<ThemeProvider>();

    // The app-state counter is readable here too - on a completely different
    // screen - which is the whole point of lifting state into a provider.
    final counterProvider = context.watch<CounterProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Theme Settings')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              themeProvider.isDark ? 'Dark Mode ON' : 'Light Mode ON',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'This switch changes the theme for every screen.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            Card(
              child: SwitchListTile(
                title: const Text('Dark Mode'),
                subtitle: const Text('App state via Provider'),
                secondary: Icon(
                  themeProvider.isDark ? Icons.dark_mode : Icons.light_mode,
                ),
                value: themeProvider.isDark,
                // The underscore means we ignore the bool the Switch hands us
                // and let the provider be the single source of truth.
                onChanged: (_) => themeProvider.toggleTheme(),
              ),
            ),
            const SizedBox(height: 24),
            // Proof that app state crosses screen boundaries.
            Card(
              child: ListTile(
                leading: const Icon(Icons.pin),
                title: const Text('App state counter'),
                subtitle: const Text('Same value, read from another screen'),
                trailing: Text(
                  '${counterProvider.count}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
