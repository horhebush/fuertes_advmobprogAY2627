// Lab Activity 1 - Ephemeral vs. App State
// Jorge Fuertes | INF231

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Entry point. The providers are placed above MaterialApp so their data is not
// destroyed when we move between screens.
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeModel()),
        ChangeNotifierProvider(create: (_) => CounterModel()),
      ],
      child: const FuertesAdvMobProg(),
    ),
  );
}

// Holds the dark/light preference for the whole app.
class ThemeModel with ChangeNotifier {
  bool _isDark = false;

  bool get isDark => _isDark;

  // Switches the theme and tells the listening widgets to rebuild.
  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }
}

// Holds a counter as app state, so it keeps its value across screens.
class CounterModel with ChangeNotifier {
  int _count = 0;

  int get count => _count;

  void increment() {
    _count++;
    notifyListeners();
  }

  void reset() {
    _count = 0;
    notifyListeners();
  }
}

// Root widget. Reads the theme from app state and passes it to MaterialApp.
class FuertesAdvMobProg extends StatelessWidget {
  const FuertesAdvMobProg({super.key});

  @override
  Widget build(BuildContext context) {
    final themeModel = context.watch<ThemeModel>();

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
      themeMode: themeModel.isDark ? ThemeMode.dark : ThemeMode.light,
      home: const CounterScreen(),
    );
  }
}

// Screen 1: the counter. Stateful because it owns the ephemeral counter.
class CounterScreen extends StatefulWidget {
  const CounterScreen({super.key});

  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen> {
  // Ephemeral state. Stored in this State object only.
  int _ephemeralCount = 0;

  // Adds one to the ephemeral counter and rebuilds this widget.
  void _incrementEphemeral() {
    setState(() {
      _ephemeralCount++;
    });
  }

  // Sets the ephemeral counter back to zero.
  void _resetEphemeral() {
    setState(() {
      _ephemeralCount = 0;
    });
  }

  // Opens the theme settings screen.
  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  // Replaces this screen with a new copy of itself. The old State object is
  // thrown away, which is how we can see the ephemeral counter reset.
  void _replaceScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const CounterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final counterModel = context.watch<CounterModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Counter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Theme Settings',
            onPressed: _openSettings,
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const _StateInfo(),
              const SizedBox(height: 16),
              _CounterCard(
                label: 'Ephemeral State',
                helper: 'setState() - resets when this screen is rebuilt',
                value: _ephemeralCount,
                accent: Theme.of(context).colorScheme.primary,
                onReset: _resetEphemeral,
              ),
              const SizedBox(height: 12),
              _CounterCard(
                label: 'App State',
                helper: 'Provider - survives navigation and screen rebuilds',
                value: counterModel.count,
                accent: Theme.of(context).colorScheme.tertiary,
                onReset: counterModel.reset,
              ),
              const SizedBox(height: 16),
              // One button raises both counters, so any difference in their
              // values comes only from where each one is stored.
              SizedBox(
                width: 320,
                child: FilledButton.icon(
                  onPressed: () {
                    _incrementEphemeral();
                    counterModel.increment();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Increment'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 320,
                child: OutlinedButton.icon(
                  onPressed: _replaceScreen,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Rebuild this screen'),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tap Increment a few times, then rebuild.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Short explanation of the two kinds of state, shown at the top of the screen.
class _StateInfo extends StatelessWidget {
  const _StateInfo();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: 320,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'State Management',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          _InfoLine(
            title: 'Ephemeral state',
            body: 'Data kept inside one widget using setState. Only that widget '
                'can see it, and it is lost when the widget is rebuilt. Good for '
                'small things like a counter or a checkbox.',
            color: scheme.primary,
          ),
          const SizedBox(height: 8),
          _InfoLine(
            title: 'App state',
            body: 'Data kept in a ChangeNotifier above the widget tree using '
                'Provider. Any screen can read or change it and it survives '
                'navigation. Good for the theme, a logged in user, or a cart.',
            color: scheme.tertiary,
          ),
        ],
      ),
    );
  }
}

// One labelled paragraph inside the explanation box.
class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.title,
    required this.body,
    required this.color,
  });

  final String title;
  final String body;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(body, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

// Displays one counter. Used for both so they look the same on screen.
class _CounterCard extends StatelessWidget {
  const _CounterCard({
    required this.label,
    required this.helper,
    required this.value,
    required this.accent,
    required this.onReset,
  });

  final String label;
  final String helper;
  final int value;
  final Color accent;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Container(
        width: 320,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Expanded so a long label does not overflow the row.
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.restart_alt, size: 20),
                  tooltip: 'Reset $label',
                  onPressed: onReset,
                ),
              ],
            ),
            Text(helper, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
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

// Screen 2: the theme toggle. Stateless because the switch reads app state.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeModel = context.watch<ThemeModel>();
    final counterModel = context.watch<CounterModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Theme Settings')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              themeModel.isDark ? 'Dark Mode ON' : 'Light Mode ON',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'This switch changes the theme for every screen.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            Card(
              child: SwitchListTile(
                title: const Text('Dark Mode'),
                subtitle: const Text('App state via Provider'),
                secondary: Icon(
                  themeModel.isDark ? Icons.dark_mode : Icons.light_mode,
                ),
                value: themeModel.isDark,
                onChanged: (_) => themeModel.toggleTheme(),
              ),
            ),
            const SizedBox(height: 16),
            // The same counter value, read from a different screen.
            Card(
              child: ListTile(
                leading: const Icon(Icons.pin),
                title: const Text('App state counter'),
                subtitle: const Text('Same value, read from another screen'),
                trailing: Text(
                  '${counterModel.count}',
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
