import 'package:flutter/material.dart';
import 'widgets.dart'; // Shared buttons
import 'login_page.dart'; // Link to Login
import 'register_page.dart'; // Link to Register

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.scale(
                scale: 1.5,
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 280,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Hear the world\nthrough text",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2C3E50),
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Stories you can see. Moment you can feel.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  color: const Color(0xFF2C3E50).withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 60),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: SketchyButton(
                      text: "Login",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: SketchyButton(
                      text: "Register",
                      isPrimary: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterPage(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
