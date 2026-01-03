import 'package:flutter/material.dart';
import 'login_page.dart'; // For Logout
import 'profile_page.dart';
import 'uploads_page.dart';
import 'tv_page.dart';
import 'radio_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // --- TOP BAR (Hello User) ---
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // Hides the back button
        toolbarHeight: 80,
        shape: const Border(
          bottom: BorderSide(color: Color(0xFF2C3E50), width: 2.0),
        ),
        title: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(
            "Hello User!",
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2C3E50),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20, top: 10),
            // We use PopupMenuButton instead of GestureDetector now
            child: PopupMenuButton<String>(
              offset: const Offset(
                0,
                65,
              ), // <--- Moves the menu down so it's under the image
              tooltip: 'Show Menu',
              elevation: 0, // No default shadow, we prefer the sketchy border
              // --- Style the Menu Box ---
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: const BorderSide(
                  color: Color(0xFF2C3E50),
                  width: 2,
                ), // Sketchy border
              ),

              // --- Handle Menu Clicks ---
              onSelected: (value) {
                if (value == 'profile') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfilePage()),
                  );
                } else if (value == 'logout') {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                }
              },

              // --- The Trigger Image (Kept exactly the same scale!) ---
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: const Color(0xFF2C3E50),
                    width: 2.5,
                  ),
                ),
                child: ClipOval(
                  child: Transform.scale(
                    scale: 1.5, // <--- Scale is preserved here
                    child: Image.asset(
                      'assets/images/profile.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              // --- The Menu Items ---
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                // 1. Header (Non-clickable info)
                PopupMenuItem<String>(
                  enabled: false, // Cannot click this header
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "EchoUser",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2C3E50),
                        ),
                      ),
                      Text(
                        "echo@cat.com",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const Divider(color: Color(0xFF2C3E50), thickness: 1),
                    ],
                  ),
                ),
                // 2. View Profile Option
                PopupMenuItem<String>(
                  value: 'profile',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.account_circle,
                        color: Color(0xFF5BC0EB),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "View Profile",
                        style: TextStyle(
                          fontSize: 18,
                          color: const Color(0xFF2C3E50),
                        ),
                      ),
                    ],
                  ),
                ),
                // 3. Logout Option
                PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      const Icon(Icons.logout, color: Colors.redAccent),
                      const SizedBox(width: 10),
                      Text(
                        "Logout",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // --- BOTTOM NAVIGATION BAR (From your sketch) ---
      // --- BOTTOM NAVIGATION BAR (Home is Active) ---
      bottomNavigationBar: Container(
        height: 80,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFF2C3E50), width: 2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Inside bottomNavigationBar
            _NavItem(
              icon: Icons.upload_file,
              label: "Upload",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UploadsPage()),
                );
              },
            ),
            _NavItem(
              icon: Icons.radio,
              label: "Radio",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RadioPage()),
                );
              },
            ),

            // --- ACTIVE TAB: HOME (Big, Blue, No Text) ---
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF5BC0EB), // Blue
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFF2C3E50), width: 2),
              ),
              child: const Icon(Icons.home, color: Colors.white, size: 32),
            ),

            _NavItem(
              icon: Icons.tv,
              label: "TV",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TvPage()),
                );
              },
            ),

            // --- INACTIVE TAB: PROFILE (Normal with Text) ---
            _NavItem(
              icon: Icons.person,
              label: "Profile",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                );
              },
            ),
          ],
        ),
      ),

      // --- MAIN BODY (The 3 Cards) ---
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 10),

          // 1. UPLOAD CARD
          SketchyCard(
            title: "My Uploads",
            subtitle: "Last file: Lecture.mp4",
            imagePath: "assets/images/uploads.png",
            color: const Color(0xFFE3F2FD),
            onTap: () {
              // Navigate to Uploads Page
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UploadsPage()),
              );
            },
          ),

          const SizedBox(height: 24),

          // 2. RADIO CARD
          SketchyCard(
            title: "Radio Stream",
            subtitle: "Watch to live world news",
            imagePath: "assets/images/radio.png",
            color: const Color(0xFFFFF3E0), // Light Orange
            imageScale: 1.3,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RadioPage()),
              );
            },
          ),

          const SizedBox(height: 24),

          // 3. TV DEMO CARD
          SketchyCard(
            title: "TV Demo",
            subtitle: "Watch with AI captions",
            imagePath: "assets/images/tv.png",
            color: const Color(0xFFE3F2FD), // Light Blue
            imageScale: 2.0,
            // TV Card onTap:
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TvPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}

// --- CUSTOM WIDGET: The Sketchy Card ---
class SketchyCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imagePath;
  final Color color;
  final VoidCallback onTap;
  final double imageScale;

  const SketchyCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.color,
    required this.onTap,
    this.imageScale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180, // Big card like sketch
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: const Color(0xFF2C3E50), width: 2),
          // Sketchy border radius (wobbly)
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(5),
            bottomLeft: Radius.circular(5),
            bottomRight: Radius.circular(20),
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              offset: Offset(4, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            // Left Side: Text
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.only(left: 20, top: 20, bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 18,
                        color: const Color(0xFF2C3E50).withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Right Side: The Cat Image
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Transform.scale(
                  scale: imageScale,
                  child: Image.asset(imagePath, fit: BoxFit.contain),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- CUSTOM WIDGET: Navigation Item ---
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _NavItem({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
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
      ),
    );
  }
}
