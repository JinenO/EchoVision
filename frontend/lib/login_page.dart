import 'package:flutter/material.dart';
import 'widgets.dart';
import 'register_page.dart';
import 'welcome_page.dart';
import 'forgot_password_page.dart';
import 'dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  // --- HELPER: Validate Email Format ---
  bool _isEmailValid(String email) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegex.hasMatch(email);
  }

  // --- HELPER: Validate Password Strength (Added Back!) ---
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
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const WelcomePage()),
              );
            }
          },
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
                "Welcome Back",
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 10),

              Text(
                "Echo missed you! Log in to continue\nhearing the world.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  color: const Color(0xFF2C3E50).withOpacity(0.6),
                ),
              ),

              const SizedBox(height: 40),

              // --- EMAIL FIELD ---
              SketchyTextField(hintText: "Email", controller: _emailController),
              const SizedBox(height: 20),

              // --- PASSWORD FIELD ---
              SketchyTextField(
                hintText: "Password",
                isPassword: true,
                controller: _passController,
              ),

              const SizedBox(height: 10),

              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ForgotPasswordPage(),
                      ),
                    );
                  },
                  child: const Text(
                    "Forgot Password?",
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF5BC0EB),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 50),

              // --- LOGIN BUTTON ---
              SizedBox(
                width: double.infinity,
                child: SketchyButton(
                  text: "Login",
                  isPrimary: true,
                  onTap: () {
                    // 1. Get Inputs
                    String email = _emailController.text.trim();
                    String password = _passController.text.trim();

                    // 2. Validate Empty
                    if (email.isEmpty || password.isEmpty) {
                      _showError("Please fill in all fields!");
                      return;
                    }

                    // 3. Validate Email Format
                    if (!_isEmailValid(email)) {
                      _showError("Please enter a valid email address.");
                      return;
                    }

                    // 4. VALIDATE PASSWORD STRENGTH (Added Logic)
                    String? passwordError = _validatePassword(password);
                    if (passwordError != null) {
                      _showError(passwordError); // Show "Need Uppercase", etc.
                      return;
                    }

                    // 5. SUCCESS
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DashboardPage(),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 30),

              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegisterPage(),
                    ),
                  );
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(fontSize: 18, color: Color(0xFF2C3E50)),
                    ),
                    Text(
                      "Sign Up",
                      style: TextStyle(
                        fontSize: 18,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5BC0EB),
                      ),
                    ),
                  ],
                ),
              ),
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
