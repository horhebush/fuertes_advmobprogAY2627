import 'package:shared_preferences/shared_preferences.dart';

// ENHANCEMENT 2: which backend authenticated the session that is running.
enum LoginType { dummyJson, firebase }

// Remembers the backend so a restart reads the profile from the right place.
Future<void> saveLoginType(LoginType type) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('loginType', type.name);
}

// Reads the saved backend, falling back to the dummyJSON one from Activity 4.
Future<LoginType> readLoginType() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('loginType') == LoginType.firebase.name
      ? LoginType.firebase
      : LoginType.dummyJson;
}
