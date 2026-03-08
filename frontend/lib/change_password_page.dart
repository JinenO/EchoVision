import 'package:flutter/material.dart';
import 'widgets.dart';
import 'api_service.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController _currentPassController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  final Color primaryColor = const Color(0xFF2C3E50);

  // --- NEW: State to track if we should unlock the rest of the form ---
  bool _isVerified = false;

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  String? _passwordError;
  String? _confirmError;

  // --- Validators ---
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

    if (_confirmPassController.text.isNotEmpty) {
      _validateConfirmPassword(_confirmPassController.text);
    }
  }

  void _validateConfirmPassword(String value) {
    if (value.isEmpty) {
      setState(() => _confirmError = null);
      return;
    }
    setState(() {
      _confirmError = value == _newPassController.text
          ? null
          : "Passwords do not match";
    });
  }

  // --- NEW: Step 1 - Verify Current Password ---
  void _handleVerifyCurrent() async {
    String current = _currentPassController.text.trim();

    if (current.isEmpty) {
      _showError("Please enter your current password.");
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    bool success = await ApiService.verifyCurrentPassword(current);

    if (mounted) Navigator.pop(context);

    if (success) {
      setState(() {
        _isVerified = true; // <--- UNLOCKS THE REST OF THE PAGE!
      });
    } else {
      _showError("Incorrect current password. Please try again.");
    }
  }

  // --- Step 2 - Save the New Password ---
  void _handleSaveNew() async {
    String current = _currentPassController.text.trim();
    String newPass = _newPassController.text.trim();
    String confirm = _confirmPassController.text.trim();

    if (newPass.isEmpty || confirm.isEmpty) {
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

    // The backend still requires the current password for maximum security
    bool success = await ApiService.changePassword(current, newPass);

    if (mounted) Navigator.pop(context);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text("Password changed successfully!"),
        ),
      );
      Navigator.pop(context);
    } else {
      _showError("Session error. Please try again.");
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

  // --- Reusable Input Field ---
  Widget _buildUniformField({
    required TextEditingController controller,
    required String label,
    bool isPassword = false,
    String? errorText,
    Widget? suffixIcon,
    void Function(String)? onChanged,
    bool readOnly = false, // <--- Added so we can lock the field
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      onChanged: onChanged,
      readOnly: readOnly,
      style: TextStyle(
        color: readOnly ? Colors.grey : Colors.black,
      ), // Grays out text if locked
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        suffixIcon: suffixIcon,
        fillColor: readOnly
            ? Colors.grey.shade100
            : Colors.white, // Grays out background if locked
        filled: readOnly,
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
          borderSide: BorderSide(
            color: readOnly ? Colors.grey : primaryColor,
            width: 2,
          ),
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
              "Change Password",
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 40),

            // --- ALWAYS VISIBLE: Current Password ---
            _buildUniformField(
              controller: _currentPassController,
              label: "Current Password",
              isPassword: _obscureCurrent,
              readOnly:
                  _isVerified, // <--- Locks the field if they already verified it!
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureCurrent ? Icons.visibility_off : Icons.visibility,
                  color: primaryColor.withOpacity(0.6),
                ),
                onPressed: () =>
                    setState(() => _obscureCurrent = !_obscureCurrent),
              ),
            ),
            const SizedBox(height: 20),

            // --- STEP 1: Show Verify Button if NOT verified ---
            if (!_isVerified)
              SizedBox(
                width: double.infinity,
                child: SketchyButton(
                  text: "Verify Current Password",
                  isPrimary: true,
                  onTap: _handleVerifyCurrent,
                ),
              ),

            // --- STEP 2: Show New Fields ONLY IF verified ---
            if (_isVerified) ...[
              _buildUniformField(
                controller: _newPassController,
                label: "New Password",
                isPassword: _obscureNew,
                errorText: _passwordError,
                onChanged: _validatePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNew ? Icons.visibility_off : Icons.visibility,
                    color: primaryColor.withOpacity(0.6),
                  ),
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                ),
              ),
              const SizedBox(height: 20),

              _buildUniformField(
                controller: _confirmPassController,
                label: "Confirm New Password",
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

              const SizedBox(height: 50),
              SizedBox(
                width: double.infinity,
                child: SketchyButton(
                  text: "Save New Password",
                  isPrimary: true,
                  onTap: _handleSaveNew,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
