import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
// Aliased because firebase_auth exports a User class of its own.
import '../models/user.dart' as models;
import '../utils/login_type.dart';

ValueNotifier<UserService> userService = ValueNotifier(UserService());

// Handles logging in and keeping the user on the device.
class UserService {
  Map<String, dynamic> data = {};

  // Sends the credentials to the API and saves whatever comes back.
  Future<Map<String, dynamic>> loginUser(
    String username,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$host/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'expiresInMins': 60,
      }),
    );

    if (response.statusCode == 200) {
      data = jsonDecode(response.body);
      await saveUserData(data);
      // ENHANCEMENT 2: remember which backend this session came from.
      await saveLoginType(LoginType.dummyJson);
      return data;
    } else {
      // The API answers a bad login with {"message": "Invalid credentials"},
      // so read that instead of putting the raw body on screen.
      String message = 'Login failed';
      try {
        message = jsonDecode(response.body)['message'] ?? message;
      } catch (_) {}
      throw Exception(message);
    }
  }

  // Saves the user from the API response to SharedPreferences.
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    final user = models.User.fromJson(userData);

    await prefs.setInt('id', user.id);
    await prefs.setString('username', user.username);
    await prefs.setString('email', user.email);
    await prefs.setString('firstName', user.firstName);
    await prefs.setString('lastName', user.lastName);
    await prefs.setString('gender', user.gender);
    await prefs.setString('image', user.image);
    await prefs.setString('accessToken', user.accessToken);
    await prefs.setString('refreshToken', user.refreshToken);

    // Support the generic token key if the response carries one.
    if (userData.containsKey('token')) {
      await prefs.setString('token', userData['token'] ?? '');
    } else if (user.accessToken.isNotEmpty) {
      await prefs.setString('token', user.accessToken);
    }
  }

  // Reads the current user, from Firestore or from SharedPreferences.
  Future<Map<String, dynamic>> getUserData() async {
    // ENHANCEMENT 3: a Firebase session keeps its profile in the cloud.
    if (await readLoginType() == LoginType.firebase) {
      return _getFirebaseUserData();
    }

    final prefs = await SharedPreferences.getInstance();

    return {
      'id': prefs.getInt('id') ?? 0,
      'username': prefs.getString('username') ?? '',
      'email': prefs.getString('email') ?? '',
      'firstName': prefs.getString('firstName') ?? '',
      'lastName': prefs.getString('lastName') ?? '',
      'gender': prefs.getString('gender') ?? '',
      'image': prefs.getString('image') ?? '',
      'accessToken': prefs.getString('accessToken') ?? '',
      'refreshToken': prefs.getString('refreshToken') ?? '',
      'token': prefs.getString('token') ?? prefs.getString('accessToken') ?? '',
    };
  }

  // The saved user as a model instead of a map.
  Future<models.User> getUser() async {
    final userData = await getUserData();
    return models.User.fromJson(userData);
  }

  // True while a token is on the device, or while Firebase holds a session.
  Future<bool> isLoggedIn() async {
    // The Firebase SDK stores and refreshes its own token, so just ask it.
    if (await readLoginType() == LoginType.firebase) return currentUser != null;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? prefs.getString('token');
    return token != null && token.isNotEmpty;
  }

  // Clears everything this service saved.
  Future<void> logout() async {
    try {
      if (await readLoginType() == LoginType.firebase) await signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      throw Exception('Failed to log out: $e');
    }
  }

  // ENHANCEMENT 1: everything below signs in against Firebase instead.

  // A getter, not a field: reading it before Firebase.initializeApp throws,
  // and the dummyJSON path builds a UserService without ever touching it.
  FirebaseAuth get firebaseAuth => FirebaseAuth.instance;

  User? get currentUser => firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();

  // Signs in an existing Firebase account.
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await saveLoginType(LoginType.firebase);
    return credential;
  }

  // Creates the Firebase account behind the sign-up form.
  Future<UserCredential> createAccount({
    required String email,
    required String password,
  }) async {
    final credential = await firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await saveLoginType(LoginType.firebase);
    return credential;
  }

  // Ends the Firebase session.
  Future<void> signOut() async {
    await firebaseAuth.signOut();
  }

  // Renames the account, on the Auth record and in the profile document.
  Future<void> updateUsername({required String username}) async {
    await currentUser!.updateDisplayName(username);
    await _profileDoc(currentUser!.uid).update({'username': username});
  }

  // Re-authenticates, then removes the profile and the account itself.
  Future<void> deleteAccount({
    required String email,
    required String password,
  }) async {
    AuthCredential credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );

    await currentUser!.reauthenticateWithCredential(credential);
    await _profileDoc(currentUser!.uid).delete();
    await currentUser!.delete();
    await firebaseAuth.signOut();
  }

  // Re-authenticates with the old password, then sets the new one.
  Future<void> resetPasswordFromCurrentPassword({
    required String currentPassword,
    required String newPassword,
    required String email,
  }) async {
    AuthCredential credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await currentUser!.reauthenticateWithCredential(credential);
    await currentUser!.updatePassword(newPassword);
  }

  // ENHANCEMENT 2: the sign-up fields Firebase Auth has nowhere to put.
  Future<void> saveUserProfile(models.User user) async {
    await _profileDoc(currentUser!.uid).set(user.toFirestore());
  }

  // One profile document per account, keyed by the Firebase uid.
  DocumentReference<Map<String, dynamic>> _profileDoc(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid);

  // Merges the Auth record with the profile document behind it.
  Future<Map<String, dynamic>> _getFirebaseUserData() async {
    final account = currentUser;
    if (account == null) return {};

    final snapshot = await _profileDoc(account.uid).get();

    return {
      ...?snapshot.data(),
      'uid': account.uid,
      'email': account.email ?? '',
      'username': account.displayName ?? snapshot.data()?['username'] ?? '',
    };
  }
}
