import 'package:flutter/material.dart';

// --- SHARED BUTTON (Unchanged) ---
class SketchyButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final bool isPrimary;

  const SketchyButton({
    super.key,
    required this.text,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFF5BC0EB) : Colors.white,
          border: Border.all(color: const Color(0xFF2C3E50), width: 2.0),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(5),
            topRight: Radius.circular(15),
            bottomLeft: Radius.circular(15),
            bottomRight: Radius.circular(5),
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              offset: Offset(3, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isPrimary ? Colors.white : const Color(0xFF2C3E50),
          ),
        ),
      ),
    );
  }
}

// --- UPDATED TEXT FIELD (With Eye Icon & Controller) ---
class SketchyTextField extends StatefulWidget {
  final String hintText;
  final bool isPassword;
  final TextEditingController? controller;
  final VoidCallback? onTap;

  const SketchyTextField({
    super.key,
    required this.hintText,
    this.isPassword = false,
    this.controller,
    this.onTap,
  });

  @override
  State<SketchyTextField> createState() => _SketchyTextFieldState();
}

class _SketchyTextFieldState extends State<SketchyTextField> {
  late bool _isObscured;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF2C3E50), width: 2.0),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(5),
          bottomLeft: Radius.circular(5),
          bottomRight: Radius.circular(10),
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black12, offset: Offset(2, 2), blurRadius: 0),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: widget.controller,
        obscureText: _isObscured,
        onTap: widget.onTap,

        // --- THE FIX IS HERE ---
        // readOnly: true,  <-- DELETE THIS OLD LINE
        readOnly: widget.onTap != null, // <-- USE THIS NEW LINE

        style: const TextStyle(
          fontSize: 20,
          color: Color(0xFF2C3E50),
          // fontFamily: 'PatrickHand', // Uncomment if you set up the font globally
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: widget.hintText,
          hintStyle: TextStyle(color: Colors.grey[400]),
          suffixIcon: widget.isPassword
              ? IconButton(
                  icon: Icon(
                    _isObscured ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _isObscured = !_isObscured;
                    });
                  },
                )
              : null,
        ),
      ),
    );
  }
}
