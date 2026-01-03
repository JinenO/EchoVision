import 'package:flutter/material.dart';
import 'widgets.dart';
import 'verification_page.dart'; // To verify the code
import 'reset_password_page.dart'; // The final destination

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();

  // --- HELPER: Validate Email Format ---
  bool _isEmailValid(String email) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegex.hasMatch(email);
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
        // Allow scrolling on small screens
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              // Icon
              const Icon(
                Icons.lock_reset_rounded,
                size: 80,
                color: Color(0xFF5BC0EB),
              ),
              const SizedBox(height: 20),

              const Text(
                "Forgot Password?",
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Don't worry! It happens.\nEnter your email to get a code.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  color: const Color(0xFF2C3E50).withOpacity(0.6),
                ),
              ),

              const SizedBox(height: 40),

              // --- EMAIL INPUT (Typing Enabled) ---
              SketchyTextField(
                hintText: "Enter your Email",
                controller: _emailController,
                // No onTap -> Typing enabled!
              ),

              const SizedBox(height: 50),

              // --- SEND CODE BUTTON ---
              SizedBox(
                width: double.infinity,
                child: SketchyButton(
                  text: "Send Code",
                  isPrimary: true,
                  onTap: () {
                    String email = _emailController.text.trim();

                    // 1. Check Empty
                    if (email.isEmpty) {
                      _showError("Please enter your email!");
                      return;
                    }

                    // 2. Check Valid Email
                    if (!_isEmailValid(email)) {
                      _showError("Please enter a valid email address.");
                      return;
                    }

                    // 3. SUCCESS -> Navigate to Verification
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VerificationPage(
                          email: email,
                          targetPage:
                              const ResetPasswordPage(), // Destination after code
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
