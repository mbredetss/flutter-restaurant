import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class UserService {
  static const String _currentUserKey = 'current_user';
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

  // Save a specific user by email
  Future<void> saveUserByEmail(String email, User user) async {
    await _initializePrefs();
    String userKey = 'user_${email.replaceAll('@', '_at_').replaceAll('.', '_dot_')}';
    await _prefs?.setString(userKey, jsonEncode(user.toMap()));
  }

  // Get a specific user by email
  Future<User?> getUserByEmail(String email) async {
    await _initializePrefs();
    String userKey = 'user_${email.replaceAll('@', '_at_').replaceAll('.', '_dot_')}';
    final userData = _prefs?.getString(userKey);
    if (userData != null) {
      final userMap = jsonDecode(userData);
      return User.fromMap(userMap);
    }
    return null;
  }

  // Save current logged in user
  Future<void> saveCurrentUser(User user) async {
    await _initializePrefs();
    await _prefs?.setString(_currentUserKey, jsonEncode(user.toMap()));
  }

  // Get current logged in user
  Future<User?> getCurrentUser() async {
    await _initializePrefs();
    final userData = _prefs?.getString(_currentUserKey);
    if (userData != null) {
      final userMap = jsonDecode(userData);
      return User.fromMap(userMap);
    }
    return null;
  }

  // Update user location for current user
  Future<void> updateUserLocation(String location) async {
    await _initializePrefs();
    final user = await getCurrentUser();
    if (user != null) {
      user.location = location;
      await saveCurrentUser(user);
      // Also update the stored user
      await saveUserByEmail(user.email, user);
    }
  }

  // Check if user exists (for login)
  Future<bool> checkUser(String email, String password) async {
    await _initializePrefs();
    final user = await getUserByEmail(email);
    if (user != null) {
      return user.email == email && user.password == password;
    }
    return false;
  }

  // Register new user
  Future<void> registerUser(String email, String password) async {
    await _initializePrefs();
    final user = User(email: email.trim(), password: password.trim());
    await saveUserByEmail(email, user);
  }

  // Log in user and set as current user
  Future<bool> loginUser(String email, String password) async {
    await _initializePrefs();
    final user = await getUserByEmail(email);
    if (user != null && user.email == email && user.password == password) {
      await saveCurrentUser(user);
      return true;
    }
    return false;
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    await _initializePrefs();
    final user = await getCurrentUser();
    return user != null;
  }

  // Clear user data (logout)
  Future<void> clearUserData() async {
    await _initializePrefs();
    await _prefs?.remove(_currentUserKey);
  }

  // Check if current user has location set
  Future<bool> hasLocationSet() async {
    await _initializePrefs();
    final user = await getCurrentUser();
    return user != null && user.location.isNotEmpty;
  }
}