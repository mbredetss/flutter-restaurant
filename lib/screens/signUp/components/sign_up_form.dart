import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../constants.dart';
import '../../../services/user_service.dart';
import '../../auth/sign_in_screen.dart';

class SignUpForm extends StatefulWidget {
  const SignUpForm({super.key});

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
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
              // Full Name Field
              TextFormField(
                controller: _nameController,
                validator: requiredValidator.call,
                onSaved: (value) {},
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(hintText: "Full Name"),
              ),
              const SizedBox(height: defaultPadding),

              // Email Field
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
                textInputAction: TextInputAction.next,
                onChanged: (value) {},
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

              // Confirm Password Field
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureText,
                validator: (value) {
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: "Confirm Password",
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
              // Sign Up Button
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate() && !_isLoading) {
                    setState(() {
                      _isLoading = true;
                    });

                    // Simulate a 3-second loading time for demonstration
                    await Future.delayed(const Duration(seconds: 3));

                    String email = _emailController.text.trim();
                    String password = _passwordController.text;

                    // Register the user
                    await UserService.instance.registerUser(email, password);

                    // Navigate to sign in screen after successful registration
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignInScreen(),
                      ),
                      (_) => true,
                    );

                    // Set loading back to false after processing
                    if (mounted) {
                      setState(() {
                        _isLoading = false;
                      });
                    }
                  }
                },
                child: const Text("Sign Up"),
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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
