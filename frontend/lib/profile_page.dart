import 'package:flutter/material.dart';
import 'widgets.dart';
import 'login_page.dart';
import 'dashboard_page.dart';
import 'edit_profile_page.dart';
import 'uploads_page.dart';
import 'tv_page.dart';
import 'radio_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // --- 1. HEADER (No Back Arrow) ---
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 80,
        shape: const Border(
          bottom: BorderSide(color: Color(0xFF2C3E50), width: 2.0),
        ),
        automaticallyImplyLeading: false, // <--- REMOVED BACK ARROW
        centerTitle: true,
        title: Text(
          "My Profile",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2C3E50),
          ),
        ),
      ),

      // --- 2. BODY ---
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
          child: Column(
            children: [
              // Picture
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF2C3E50), width: 3),
                ),
                child: ClipOval(
                  child: Transform.scale(
                    scale: 1.3,
                    child: Image.asset(
                      'assets/images/profile.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Name
              Text(
                "EchoUser",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 30),

              // Info Box
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFF2C3E50), width: 2),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(5),
                    bottomLeft: Radius.circular(5),
                    bottomRight: Radius.circular(15),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      offset: Offset(4, 4),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _ProfileRow(
                      icon: Icons.email_outlined,
                      text: "echo@cat.com",
                    ),
                    const Divider(color: Color(0xFF2C3E50), thickness: 1),
                    _ProfileRow(
                      icon: Icons.remove_red_eye_outlined,
                      text: "•••••••••••",
                    ),
                    const Divider(color: Color(0xFF2C3E50), thickness: 1),
                    _ProfileRow(
                      icon: Icons.calendar_today,
                      text: "20 July 2024",
                    ),
                    const Divider(color: Color(0xFF2C3E50), thickness: 1),
                    _ProfileRow(icon: Icons.person_outline, text: "Male"),
                    const Divider(color: Color(0xFF2C3E50), thickness: 1),

                    // Logout
                    InkWell(
                      onTap: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                          (route) => false,
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.logout,
                              color: Colors.redAccent,
                              size: 26,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              "Log out",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              // Edit Button
              SizedBox(
                width: 200,
                child: SketchyButton(
                  text: "Edit Profile",
                  onTap: () {
                    // Navigate to the new Edit Page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditProfilePage(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),

      // --- BOTTOM NAVIGATION (Profile is Active) ---
      bottomNavigationBar: Container(
        height: 80,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFF2C3E50), width: 2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // 1. UPLOAD BUTTON (Updated to be Clickable!)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UploadsPage()),
                );
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.upload_file,
                    color: Color(0xFF2C3E50),
                    size: 28,
                  ),
                  Text(
                    "Upload",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // 2. RADIO BUTTON
            GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const RadioPage()),
                );
              },
              child: const _BottomIcon(icon: Icons.radio, label: "Radio"),
            ),

            // 2. HOME BUTTON (Inactive - Standard Size)
            GestureDetector(
              onTap: () {
                // Go back to Dashboard
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const DashboardPage()),
                );
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.home, color: Color(0xFF2C3E50), size: 28),
                  Text(
                    "Home",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const TvPage()),
                );
              },
              child: const _BottomIcon(icon: Icons.tv, label: "TV"),
            ),

            // 3. PROFILE BUTTON (Active - Big & Blue)
            // Keep this exactly as is! It correctly shows we are on the Profile Page.
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF5BC0EB), // Blue
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFF2C3E50), width: 2),
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 32),
            ),
          ],
        ),
      ),
    );
  }
}

// --- HELPERS ---
class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _ProfileRow({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF2C3E50), size: 26),
          const SizedBox(width: 16),
          Text(
            text,
            style: TextStyle(
              fontSize: 20,
              color: const Color(0xFF2C3E50),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  const _BottomIcon({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: const Color(0xFF2C3E50), size: 28),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
