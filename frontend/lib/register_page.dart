import 'package:flutter/material.dart';
import 'widgets.dart';
import 'verification_page.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  // --- VALIDATION HELPERS ---
  bool _isEmailValid(String email) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegex.hasMatch(email);
  }

  String? _validatePassword(String password) {
    if (password.length < 8) return "Password must be at least 8 characters.";
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return "Need at least one Uppercase letter (A-Z).";
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      return "Need at least one Lowercase letter (a-z).";
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return "Need at least one Number (0-9).";
    }
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return "Need at least one Symbol (!@#\$%...).";
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2C3E50)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const Text(
                "Create Account",
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Create an account so you can see\nthe stories",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  color: const Color(0xFF2C3E50).withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 40),

              // --- EMAIL FIELD (Clean) ---
              SketchyTextField(
                hintText: "Email",
                controller: _emailController,
                // Removed onTap: ... so you can type!
              ),
              const SizedBox(height: 20),

              // --- PASSWORD FIELD (Clean) ---
              SketchyTextField(
                hintText: "Password",
                isPassword: true,
                controller: _passController,
                // Removed onTap: ... so you can type!
              ),
              const SizedBox(height: 20),

              // --- CONFIRM PASSWORD FIELD (Clean) ---
              SketchyTextField(
                hintText: "Confirm Password",
                isPassword: true,
                controller: _confirmController,
                // Removed onTap: ... so you can type!
              ),

              const SizedBox(height: 50),

              // --- SIGN UP BUTTON ---
              SizedBox(
                width: double.infinity,
                child: SketchyButton(
                  text: "Sign up",
                  isPrimary: true,
                  onTap: () {
                    // 1. Get Inputs
                    String email = _emailController.text.trim();
                    String password = _passController.text.trim();
                    String confirm = _confirmController.text.trim();

                    // 2. Validate Empty
                    if (email.isEmpty || password.isEmpty || confirm.isEmpty) {
                      _showError("Please fill in all fields!");
                      return;
                    }

                    // 3. Validate Email
                    if (!_isEmailValid(email)) {
                      _showError("Please enter a valid email address.");
                      return;
                    }

                    // 4. Validate Password Strength
                    String? passwordError = _validatePassword(password);
                    if (passwordError != null) {
                      _showError(passwordError);
                      return;
                    }

                    // 5. Validate Match
                    if (password != confirm) {
                      _showError("Passwords do not match!");
                      return;
                    }

                    // 6. Success -> Move to Verification
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VerificationPage(email: email),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
                child: const Text(
                  "Already have an account",
                  style: TextStyle(
                    fontSize: 18,
                    decoration: TextDecoration.underline,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.redAccent,
        content: Text(
          message,
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }
}
