import 'package:flutter/material.dart';

// Holds the dark/light preference for the whole app. Registered above
// MaterialApp so the choice survives moving between screens.
class ThemeProvider with ChangeNotifier {
  bool _isDark = false;

  bool get isDark => _isDark;

  // Switches the theme and rebuilds the widgets listening to this provider.
  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }

  static const Color _seed = Color(0xFF2E7D6F);

  ThemeData get lightTheme => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seed,
          brightness: Brightness.light,
        ),
        fontFamily: 'Poppins',
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: false),
      );

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
