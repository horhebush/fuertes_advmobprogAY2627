// Lab Activity 2 - API
// Jorge Fuertes | INF231
//
// Demi Mart, a store that lists products coming from a REST API.
//
// Folders: models (data classes), services (API calls), providers (app state),
// screens (pages), widgets (shared UI), constants (values from .env).
//
// Enhancements:
//   1 - search bar above the product list  (screens/product_screen.dart)
//   2 - details page when a card is tapped (screens/product_details_screen.dart)
//   3 - settings page with the theme switch (screens/settings_screen.dart)

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

// Async because the .env file has to be loaded before any API call is made.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((
    _,
  ) async {
    await dotenv.load(fileName: 'assets/.env');
    runApp(const FuertesAdvMobProg());
  });
}

// Root widget of the app.
class FuertesAdvMobProg extends StatelessWidget {
  const FuertesAdvMobProg({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      // ScreenUtilInit sets the design size the layout was made for, so sizes
      // written as 16.sp or 12.h scale on bigger and smaller phones.
      child: ScreenUtilInit(
        designSize: const Size(412, 715),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (build, child) {
          final themeModel = build.watch<ThemeProvider>();
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: themeModel.lightTheme,
            darkTheme: themeModel.darkTheme,
            themeMode: themeModel.isDark ? ThemeMode.dark : ThemeMode.light,
            title: 'Demi Mart',
            initialRoute: '/home',
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
