import 'package:flutter/material.dart';
import 'widgets.dart';
import 'login_page.dart';

class VerificationPage extends StatefulWidget {
  final String email;
  final Widget? targetPage;

  const VerificationPage({super.key, required this.email, this.targetPage});

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  final TextEditingController _codeController = TextEditingController();

  // SIMULATED CORRECT CODE FOR TESTING
  final String correctCode = "123456";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Ensure white background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2C3E50)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        // Added scroll view for smaller screens
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const Icon(
                Icons.mark_email_read_outlined,
                size: 80,
                color: Color(0xFF5BC0EB),
              ),
              const SizedBox(height: 20),

              const Text(
                "Verify Email",
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "We sent a secret code to:\n${widget.email}",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  color: const Color(0xFF2C3E50).withOpacity(0.6),
                ),
              ),

              const SizedBox(height: 40),

              // --- CODE INPUT FIELD ---
              SketchyTextField(
                hintText: "Enter 6-digit Code",
                controller: _codeController,
                // Removed onTap so you can type!
              ),

              const SizedBox(height: 20),

              // --- RESEND CODE BUTTON ---
              GestureDetector(
                onTap: () {
                  // Simulate Resending
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Color(0xFF5BC0EB), // Blue
                      content: Text("New code sent! Check your inbox."),
                    ),
                  );
                },
                child: const Text(
                  "Didn't receive code? Resend",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // --- VERIFY BUTTON ---
              SizedBox(
                width: double.infinity,
                child: SketchyButton(
                  text: "Verify",
                  isPrimary: true,
                  onTap: () {
                    String input = _codeController.text.trim();

                    // 1. CHECK EMPTY
                    if (input.isEmpty) {
                      _showError("Please enter the code!");
                      return;
                    }

                    // 2. CHECK LENGTH (Must be exact)
                    if (input.length != 6) {
                      _showError("Code must be exactly 6 digits.");
                      return;
                    }

                    // 3. CHECK IF CORRECT (Testing: 123456)
                    if (input != correctCode) {
                      _showError("Wrong code! Please try again.");
                      return;
                    }

                    // 4. SUCCESS!
                    _showSuccess("Verified Successfully!");

                    // Navigate logic...
                    if (widget.targetPage != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => widget.targetPage!,
                        ),
                      );
                    } else {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                        (route) => false,
                      );
                    }
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
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Helper for Green Success Message
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
