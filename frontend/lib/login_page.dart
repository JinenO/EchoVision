import 'package:flutter/material.dart';
import 'widgets.dart';
import 'register_page.dart';
import 'welcome_page.dart';
import 'forgot_password_page.dart';
import 'dashboard_page.dart';
import 'api_service.dart'; // Make sure this is imported!

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  final Color primaryColor = const Color(0xFF2C3E50);

  // --- State for UI ---
  bool _obscurePassword = true;
  String? _emailError;
  String? _passwordError;

  // --- Real-time Validation Functions ---
  void _validateEmail(String value) {
    if (value.isEmpty) {
      setState(() => _emailError = null);
      return;
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    setState(() {
      _emailError = emailRegex.hasMatch(value)
          ? null
          : "Enter a valid email address";
    });
  }

  void _validatePassword(String value) {
    if (value.isEmpty) {
      setState(() => _passwordError = null);
      return;
    }
    if (value.length < 8) {
      setState(() => _passwordError = "Must be at least 8 characters.");
      return;
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      setState(() => _passwordError = "Need at least one Uppercase letter.");
      return;
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      setState(() => _passwordError = "Need at least one Lowercase letter.");
      return;
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      setState(() => _passwordError = "Need at least one Number.");
      return;
    }
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      setState(() => _passwordError = "Need at least one Symbol.");
      return;
    }
    setState(() => _passwordError = null); // Valid
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

              Text(
                "Welcome Back",
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 10),

              Text(
                "Echo missed you! Log in to continue\nhearing the world.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  color: primaryColor.withOpacity(0.6),
                ),
              ),

              const SizedBox(height: 40),

              // --- EMAIL FIELD (Floating Label + Validation) ---
              _buildUniformField(
                controller: _emailController,
                label: "Email",
                errorText: _emailError,
                onChanged: _validateEmail,
              ),
              const SizedBox(height: 20),

              // --- PASSWORD FIELD (Floating Label + Validation + Eye Icon) ---
              _buildUniformField(
                controller: _passController,
                label: "Password",
                isPassword: _obscurePassword,
                errorText: _passwordError,
                onChanged: _validatePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: primaryColor.withOpacity(0.6),
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
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
                  onTap: _handleLogin,
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

  // Exact match to the Register Page helper
  Widget _buildUniformField({
    required TextEditingController controller,
    required String label,
    bool isPassword = false,
    String? errorText,
    Widget? suffixIcon,
    void Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        suffixIcon: suffixIcon,
        labelStyle: TextStyle(color: primaryColor.withOpacity(0.6)),
        floatingLabelStyle: TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.bold,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2.5),
        ),
      ),
    );
  }

  void _handleLogin() async {
    String email = _emailController.text.trim();
    String password = _passController.text.trim();

    // 1. Check for empty fields
    if (email.isEmpty || password.isEmpty) {
      _showError("Please fill in all fields!");
      return;
    }

    // 2. Check for active UI validation errors
    if (_emailError != null || _passwordError != null) {
      _showError("Please fix the errors in the form before logging in.");
      return;
    }

    // 3. Show Loading Spinner
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // 4. Call Backend
    final result = await ApiService.login(email: email, password: password);

    // 5. Hide Loading Spinner
    if (mounted) Navigator.pop(context);

    // 6. Handle Response
    if (result["success"] == true) {
      // NEW: Save the token so the Profile Page can use it!
      ApiService.currentToken = result["token"];
      
      // SUCCESS! Navigate to Dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardPage()),
      );
    } else if (result["error"] == "unverified") {
      _showError("Please verify your email address first.");
    } else if (result["error"] == "network") {
      _showError("Network error. Could not connect to the server.");
    } else {
      _showError("Incorrect email or password.");
    }
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
