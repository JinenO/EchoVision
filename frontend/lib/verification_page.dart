import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'widgets.dart';
import 'login_page.dart';
import 'api_service.dart';

class VerificationPage extends StatefulWidget {
  final String email;
  final Widget? targetPage;

  const VerificationPage({super.key, required this.email, this.targetPage});

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  // --- Create 6 Controllers and 6 FocusNodes ---
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  final Color primaryColor = const Color(0xFF2C3E50);

  @override
  void dispose() {
    // Clean up memory when page is closed
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
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
              const Icon(
                Icons.mark_email_read_outlined,
                size: 80,
                color: Color(0xFF5BC0EB),
              ),
              const SizedBox(height: 20),

              Text(
                "Verify Email",
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "We sent a secret code to:\n${widget.email}",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: primaryColor.withOpacity(0.6),
                ),
              ),

              const SizedBox(height: 40),

              // --- THE 6 OTP BOXES ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) => _buildCodeBox(index)),
              ),

              const SizedBox(height: 40),

              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Color(0xFF5BC0EB),
                      content: Text("New code sent! Check your inbox."),
                    ),
                  );
                },
                child: Text(
                  "Didn't receive code? Resend",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                    color: primaryColor,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: SketchyButton(
                  text: "Verify",
                  isPrimary: true,
                  onTap: _handleVerify, // Call the backend function!
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper Widget for a single number box
  Widget _buildCodeBox(int index) {
    return SizedBox(
      width: 45,
      height: 55,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1, // Only 1 character allowed
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ], // Block letters
        decoration: InputDecoration(
          counterText: "", // Hides the "0/1" text below the box
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryColor, width: 2.5),
          ),
        ),
        onChanged: (value) {
          // If user types a number, jump to the next box
          if (value.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          }
          // If user deletes a number, jump back to the previous box
          else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }

  // Handle the backend link
  void _handleVerify() async {
    // Combine all 6 boxes into one string
    String code = _controllers.map((c) => c.text).join();

    if (code.length != 6) {
      _showError("Please enter all 6 digits.");
      return;
    }

    // Show loading spinner
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Call the Backend!
    bool success = await ApiService.verifyEmail(
      email: widget.email,
      code: code,
    );

    // Close loading spinner
    Navigator.pop(context);

    if (success) {
      _showSuccess("Verified Successfully! You can now log in.");

      // Navigate to Login Page
      if (widget.targetPage != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => widget.targetPage!),
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    } else {
      _showError("Wrong code! Please try again.");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.redAccent,
        content: Text(message, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        content: Text(message, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}
