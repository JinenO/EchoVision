import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'widgets.dart';
import 'verification_page.dart';
import 'login_page.dart';
import 'api_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  String? _selectedGender;
  final Color primaryColor = const Color(0xFF2C3E50);

  // --- NEW: State variables for Password Visibility ---
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  // --- NEW: State variables for Error Messages ---
  String? _emailError;
  String? _passwordError;
  String? _confirmError;

  // --- NEW: Real-time Validation Functions ---
  void _validateEmail(String value) {
    if (value.isEmpty) {
      setState(
        () => _emailError = null,
      ); // Don't show error if empty (handled on submit)
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
    setState(() => _passwordError = null); // Password is valid

    // Re-check confirm password if user edits the main password
    if (_confirmController.text.isNotEmpty) {
      _validateConfirmPassword(_confirmController.text);
    }
  }

  void _validateConfirmPassword(String value) {
    if (value.isEmpty) {
      setState(() => _confirmError = null);
      return;
    }
    setState(() {
      _confirmError = value == _passController.text
          ? null
          : "Passwords do not match";
    });
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
            children: [
              Text(
                "Create Account",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 30),

              _buildUniformField(
                controller: _userController,
                label: "Username",
              ),
              const SizedBox(height: 15),

              // EMAIL FIELD (With Validation)
              _buildUniformField(
                controller: _emailController,
                label: "Email",
                errorText: _emailError,
                onChanged: _validateEmail,
              ),
              const SizedBox(height: 15),

              GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: _buildUniformField(
                    controller: _birthdayController,
                    label: "Birthday (YYYY-MM-DD)",
                  ),
                ),
              ),
              const SizedBox(height: 15),

              _buildGenderDropdown(),
              const SizedBox(height: 15),

              // PASSWORD FIELD (With Visibility & Validation)
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
              const SizedBox(height: 15),

              // CONFIRM PASSWORD FIELD (With Visibility & Validation)
              _buildUniformField(
                controller: _confirmController,
                label: "Confirm Password",
                isPassword: _obscureConfirm,
                errorText: _confirmError,
                onChanged: _validateConfirmPassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                    color: primaryColor.withOpacity(0.6),
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: SketchyButton(
                  text: "Sign up",
                  isPrimary: true,
                  onTap: _handleSignUp,
                ),
              ),

              const SizedBox(height: 30),

              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account? ",
                      style: TextStyle(fontSize: 18, color: Color(0xFF2C3E50)),
                    ),
                    Text(
                      "Login",
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
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // UPDATED HELPER: Now supports errorText, suffixIcon, and onChanged
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
      onChanged: onChanged, // Triggers validation as user types
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText, // Shows red text below field if there is an error
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

  Widget _buildGenderDropdown() {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: "Gender",
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2.5),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedGender,
          isExpanded: true,
          hint: Text(
            "Select Gender",
            style: TextStyle(
              color: primaryColor.withOpacity(0.6),
              fontSize: 16,
            ),
          ),
          itemHeight: 50,
          items: ["Male", "Female", "Other"].map((val) {
            return DropdownMenuItem(
              value: val,
              child: Text(val, style: TextStyle(color: primaryColor)),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedGender = val),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(
        () =>
            _birthdayController.text = DateFormat('yyyy-MM-dd').format(picked),
      );
    }
  }

  void _handleSignUp() async {
    final email = _emailController.text.trim();
    final password = _passController.text.trim();
    final username = _userController.text.trim();
    final birthday = _birthdayController.text.trim(); // Get birthday text

    // 1. Check for empty fields (Added birthday check)
    if (email.isEmpty ||
        password.isEmpty ||
        username.isEmpty ||
        _selectedGender == null ||
        birthday.isEmpty) {
      _showError("Please fill in all fields, including Gender and Birthday!");
      return;
    }

    // 2. Check for active errors
    if (_emailError != null ||
        _passwordError != null ||
        _confirmError != null) {
      _showError("Please fix the errors in the form before submitting.");
      return;
    }

    // --- NEW: Show a loading circle while waiting for the server ---
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // --- NEW: Wrap the API call in a try-catch block ---
    try {
      bool success = await ApiService.register(
        email: email,
        password: password,
        username: username,
        gender: _selectedGender!,
        birthday: birthday,
      );

      // Close the loading circle
      Navigator.pop(context);

      if (success) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VerificationPage(email: email),
          ),
        );
      } else {
        _showError("Registration failed. Email might already be taken.");
      }
    } catch (e) {
      // Close the loading circle if an error happens
      Navigator.pop(context);

      // Print the exact error to the terminal so you can read it
      print("CRASH AVOIDED - API Error: $e");
      _showError("Network error: Could not connect to the server.");
    }
  }
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent,
      ),
    );
  }
}
