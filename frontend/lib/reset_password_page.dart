import 'package:flutter/material.dart';
import 'widgets.dart';
import 'login_page.dart'; // To go back to login after success

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  // --- HELPER: Validate Password Strength ---
  String? _validatePassword(String password) {
    if (password.length < 8) return "Password must be at least 8 characters.";
    if (!password.contains(RegExp(r'[A-Z]')))
      return "Need at least one Uppercase letter (A-Z).";
    if (!password.contains(RegExp(r'[a-z]')))
      return "Need at least one Lowercase letter (a-z).";
    if (!password.contains(RegExp(r'[0-9]')))
      return "Need at least one Number (0-9).";
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')))
      return "Need at least one Symbol (!@#\$%...).";
    return null; // Valid!
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
                "Reset Password",
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Enter your new password below.\nMake it tricky!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  color: const Color(0xFF2C3E50).withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 40),

              // --- NEW PASSWORD (Typing Enabled) ---
              SketchyTextField(
                hintText: "New Password",
                isPassword: true,
                controller: _passController,
                // No onTap -> Allows typing!
              ),
              const SizedBox(height: 20),

              // --- CONFIRM PASSWORD (Typing Enabled) ---
              SketchyTextField(
                hintText: "Confirm Password",
                isPassword: true,
                controller: _confirmController,
                // No onTap -> Allows typing!
              ),

              const SizedBox(height: 50),

              // --- RESET BUTTON ---
              SizedBox(
                width: double.infinity,
                child: SketchyButton(
                  text: "Save New Password",
                  isPrimary: true,
                  onTap: () {
                    String pass = _passController.text.trim();
                    String confirm = _confirmController.text.trim();

                    // 1. Check Empty
                    if (pass.isEmpty || confirm.isEmpty) {
                      _showError("Please fill in both fields.");
                      return;
                    }

                    // 2. Validate Password Strength
                    String? error = _validatePassword(pass);
                    if (error != null) {
                      _showError(error);
                      return;
                    }

                    // 3. Check Match
                    if (pass != confirm) {
                      _showError("Passwords do not match!");
                      return;
                    }

                    // 4. SUCCESS -> Go to Login
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                      (route) => false,
                    );

                    // Show Green Success Message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Colors.green,
                        content: Text(
                          "Password Reset Successful! Please Login.",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper for Red Error Message
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
