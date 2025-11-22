import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../findRestaurants/find_restaurants_screen.dart';
import '../../../constants.dart';
import '../../../services/user_service.dart';
import '../../../entry_point.dart';
import '../forgot_password_screen.dart';

class SignInForm extends StatefulWidget {
  const SignInForm({super.key});

  @override
  State<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<SignInForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                validator: emailValidator.call,
                onSaved: (value) {},
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: "Email Address"),
              ),
              const SizedBox(height: defaultPadding),

              // Password Field
              TextFormField(
                controller: _passwordController,
                obscureText: _obscureText,
                validator: passwordValidator.call,
                onSaved: (value) {},
                decoration: InputDecoration(
                  hintText: "Password",
                  suffixIcon: GestureDetector(
                    onTap: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                    child: _obscureText
                        ? const Icon(Icons.visibility_off, color: bodyTextColor)
                        : const Icon(Icons.visibility, color: bodyTextColor),
                  ),
                ),
              ),
              const SizedBox(height: defaultPadding),

              // Forget Password
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ForgotPasswordScreen(),
                  ),
                ),
                child: Text(
                  "Forget Password?",
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall!
                      .copyWith(fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: defaultPadding),

              // Sign In Button
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate() && !_isLoading) {
                    setState(() {
                      _isLoading = true;
                    });

                    // Simulate a 3-second loading time for demonstration
                    await Future.delayed(const Duration(seconds: 3));

                    String email = _emailController.text.trim();
                    String password = _passwordController.text.trim();

                    bool loginSuccess = await UserService.instance.checkUser(email, password);

                    if (loginSuccess) {
                      // Check if user already has a location set
                      bool hasLocation = await UserService.instance.hasLocationSet();

                      if (hasLocation) {
                        // If user already has location, go directly to EntryPoint
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EntryPoint(),
                          ),
                          (_) => true,
                        );
                      } else {
                        // If user doesn't have location, navigate to FindRestaurantsScreen to set location
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FindRestaurantsScreen(),
                          ),
                          (_) => true,
                        );
                      }
                    } else {
                      // Show error message
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Invalid email or password'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }

                    // Set loading back to false after processing
                    if (mounted) {
                      setState(() {
                        _isLoading = false;
                      });
                    }
                  }
                },
                child: const Text("Sign in"),
              ),
            ],
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.transparent,
            child: Center(
              child: Lottie.asset(
                'assets/animations/Food.json',
                width: 200,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
