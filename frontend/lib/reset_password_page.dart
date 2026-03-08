import 'package:flutter/material.dart';
import 'widgets.dart';
import 'login_page.dart';
import 'api_service.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;
  final String code;
  const ResetPasswordPage({super.key, required this.email, required this.code});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  final Color primaryColor = const Color(0xFF2C3E50);

  // --- State for Real-Time Validation & Visibility ---
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  String? _passwordError;
  String? _confirmError;

  // --- Real-Time Validators ---
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
    setState(() => _passwordError = null);

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

  void _handleSave() async {
    String pass = _passController.text.trim();
    String confirm = _confirmController.text.trim();

    if (pass.isEmpty || confirm.isEmpty) {
      _showError("Please fill in all fields.");
      return;
    }

    if (_passwordError != null || _confirmError != null) {
      _showError("Please fix the errors before saving.");
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    bool success = await ApiService.resetPassword(
      widget.email,
      widget.code,
      pass,
    );

    if (mounted) Navigator.pop(context);

    if (success) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text("Password Reset Successful! Please Login."),
        ),
      );
    } else {
      _showError("Session expired. Please try again.");
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

  // --- Reusable Input Field Widget ---
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
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              "New Password",
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 40),

            _buildUniformField(
              controller: _passController,
              label: "New Password",
              isPassword: _obscurePassword,
              errorText: _passwordError,
              onChanged: _validatePassword, // Real-time trigger
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: primaryColor.withOpacity(0.6),
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            const SizedBox(height: 20),

            _buildUniformField(
              controller: _confirmController,
              label: "Confirm Password",
              isPassword: _obscureConfirm,
              errorText: _confirmError,
              onChanged: _validateConfirmPassword, // Real-time trigger
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                  color: primaryColor.withOpacity(0.6),
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),

            const SizedBox(height: 50),
            SizedBox(
              width: double.infinity,
              child: SketchyButton(
                text: "Save New Password",
                isPrimary: true,
                onTap: _handleSave,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
