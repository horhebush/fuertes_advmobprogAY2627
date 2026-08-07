import 'package:flutter/material.dart';

/// The PROVIDER layer — app state carried over from Lab Activity 1.
///
/// Holds the light/dark preference for the whole app. Because it is registered
/// with a ChangeNotifierProvider above MaterialApp, the preference survives
/// navigation between the home, details and settings screens.
class ThemeProvider with ChangeNotifier {
  bool _isDark = false;

  /// Read-only view of the current mode.
  bool get isDark => _isDark;

  /// Flips the theme and rebuilds every widget listening to this provider.
  ///
  /// Called by the switch on the settings screen (ENHANCEMENT 3).
  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }

  /// Seed colour shared by both themes so branding stays consistent.
  static const Color _seed = Color(0xFF2E7D6F);

  /// ThemeData used when [isDark] is false.
  ///
  /// Declared here rather than in main.dart so all styling decisions live in one
  /// place, and both themes are guaranteed to stay in step with each other.
  ThemeData get lightTheme => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seed,
          brightness: Brightness.light,
        ),
        fontFamily: 'Poppins',
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: false),
      );

  /// ThemeData used when [isDark] is true.
  ThemeData get darkTheme => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seed,
          brightness: Brightness.dark,
        ),
        fontFamily: 'Poppins',
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: false),
      );
}
