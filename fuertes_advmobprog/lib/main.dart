// =============================================================================
// Lab Activity 2 - API
// Jorge Fuertes | INF231
//
// Demi Mart: a storefront that lists products fetched from a REST API.
//
// Design pattern (layered / separation of concerns):
//
//   models/    - plain Dart classes mirroring the JSON shape (Product)
//   services/  - the only layer that talks HTTP and decodes JSON
//   providers/ - app state shared across screens (ThemeProvider)
//   screens/   - full pages the Navigator routes between
//   widgets/   - small reusable presentation pieces (CustomText)
//   constants  - environment-driven values read from assets/.env
//
// Enhancements implemented (each is marked in the source where it lives):
//   ENHANCEMENT 1 - search bar above the product list  -> screens/product_screen.dart
//   ENHANCEMENT 2 - details page when a card is tapped -> screens/product_details_screen.dart
//   ENHANCEMENT 3 - settings page with the theme switch -> screens/settings_screen.dart
// =============================================================================

// packages
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

// screens
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';

// providers
import 'providers/theme_provider.dart';

/// Entry point.
///
/// Marked async because the .env file must be read from disk before any code
/// touches `host`. ensureInitialized() is required first: loading assets needs
/// the engine bindings to be up, which normally only happens inside runApp.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait, then load the environment and start the app. Awaiting
  // dotenv.load before runApp guarantees constants.host is populated by the
  // time the first network call is made.
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((
    _,
  ) async {
    await dotenv.load(fileName: 'assets/.env');
    runApp(const FuertesAdvMobProg());
  });
}

/// Root widget of the application.
class FuertesAdvMobProg extends StatelessWidget {
  const FuertesAdvMobProg({super.key});

  @override
  Widget build(BuildContext context) {
    // ChangeNotifierProvider sits above MaterialApp so the theme preference is
    // reachable from - and survives navigation between - every screen.
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      // ScreenUtilInit captures the design canvas the UI was laid out against.
      // Sizes written as `16.sp` / `12.h` are then scaled proportionally, so the
      // layout holds its proportions on phones larger or smaller than this.
      child: ScreenUtilInit(
        designSize: const Size(412, 715),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (build, child) {
          // watch() rebuilds MaterialApp whenever the theme is toggled.
          final themeModel = build.watch<ThemeProvider>();
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: themeModel.lightTheme,
            darkTheme: themeModel.darkTheme,
            themeMode: themeModel.isDark ? ThemeMode.dark : ThemeMode.light,
            title: 'Demi Mart',
            initialRoute: '/home',
            // Named routes for the two top-level pages. The details page is
            // pushed with a MaterialPageRoute instead, because it needs a
            // Product instance passed to it in a type-safe way.
            routes: {
              '/home': (context) => const HomeScreen(),
              '/settings': (context) => const SettingsScreen(),
            },
          );
        },
      ),
    );
  }
}
