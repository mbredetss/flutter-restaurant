import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';
import 'screens/onboarding/onboarding_scrreen.dart';
import 'entry_point.dart';
import 'screens/auth/sign_in_screen.dart';
import 'services/user_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final bool onboarded = prefs.getBool('onboarded') ?? false;
  final bool isLoggedIn = await UserService.instance.isLoggedIn();

  runApp(MyApp(onboarded: onboarded, isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool onboarded;
  final bool isLoggedIn;

  const MyApp({super.key, required this.onboarded, required this.isLoggedIn});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The Flutter Way - Foodly UI Kit',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: bodyTextColor),
          bodySmall: TextStyle(color: bodyTextColor),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          contentPadding: EdgeInsets.all(defaultPadding),
          hintStyle: TextStyle(color: bodyTextColor),
        ),
      ),
      home: isLoggedIn ? const EntryPoint() : (onboarded ? const SignInScreen() : const OnboardingScreen()),
    );
  }
}
