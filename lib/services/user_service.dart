import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class UserService {
  static const String _userKey = 'user_data';
  static UserService? _instance;
  static SharedPreferences? _prefs;
  static bool _initialized = false;

  static UserService get instance {
    _instance ??= UserService._init();
    return _instance!;
  }

  UserService._init() {
    _initializePrefs();
  }

  static Future<void> _initializePrefs() async {
    if (!_initialized) {
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
    }
  }

  // Save user data
  Future<void> saveUser(User user) async {
    await _initializePrefs();
    await _prefs?.setString(_userKey, jsonEncode(user.toMap()));
  }

  // Get user data
  Future<User?> getUser() async {
    await _initializePrefs();
    final userData = _prefs?.getString(_userKey);
    if (userData != null) {
      final userMap = jsonDecode(userData);
      return User.fromMap(userMap);
    }
    return null;
  }

  // Update user location
  Future<void> updateUserLocation(String location) async {
    await _initializePrefs();
    final user = await getUser();
    if (user != null) {
      user.location = location;
      await saveUser(user);
    }
  }

  // Check if user exists (for login)
  Future<bool> checkUser(String email, String password) async {
    await _initializePrefs();
    final user = await getUser();
    if (user != null) {
      return user.email == email && user.password == password;
    }
    return false;
  }

  // Register new user
  Future<void> registerUser(String email, String password) async {
    await _initializePrefs();
    final user = User(email: email.trim(), password: password.trim());
    await saveUser(user);
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    await _initializePrefs();
    final user = await getUser();
    return user != null;
  }

  // Clear user data (logout)
  Future<void> clearUserData() async {
    await _initializePrefs();
    await _prefs?.remove(_userKey);
  }

  // Check if user has location set
  Future<bool> hasLocationSet() async {
    await _initializePrefs();
    final user = await getUser();
    return user != null && user.location.isNotEmpty;
  }
}