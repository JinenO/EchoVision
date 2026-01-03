import 'package:flutter/material.dart';
import 'dashboard_page.dart';
import 'profile_page.dart';
import 'uploads_page.dart';
import 'video_player_page.dart';
import 'radio_page.dart';

class TvPage extends StatelessWidget {
  const TvPage({super.key});

  @override
  Widget build(BuildContext context) {
    // SIMPLIFIED DATA: Just 2 Videos, both "Transcribed"
    final List<Map<String, String>> channels = [
      {
        "name": "Daily News Clip",
        "status": "Transcribed",
        "file": "Daily_News_Summary.mp4",
        "color": "0xFFE3F2FD", // Light Blue
      },
      {
        "name": "Cooking Show",
        "status": "Transcribed",
        "file": "Pasta_Cooking_Demo.mp4",
        "color": "0xFFF9F7F1", // Cream
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,

      // --- HEADER ---
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          "TV Demo",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2C3E50),
          ),
        ),
        centerTitle: true,
        shape: const Border(
          bottom: BorderSide(color: Color(0xFF2C3E50), width: 2.0),
        ),
      ),

      // --- BODY ---
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Available Demos:",
              style: TextStyle(
                fontSize: 24,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 20),

            // GRID FOR 2 ITEMS
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 items side by side
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.8, // Taller cards
                ),
                itemCount: channels.length,
                itemBuilder: (context, index) {
                  return _ChannelCard(
                    title: channels[index]["name"]!,
                    status: channels[index]["status"]!,
                    fileName: channels[index]["file"]!,
                    colorCode: int.parse(channels[index]["color"]!),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // --- BOTTOM NAVIGATION (TV Active) ---
      bottomNavigationBar: Container(
        height: 80,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFF2C3E50), width: 2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // 1. Upload
            GestureDetector(
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const UploadsPage()),
              ),
              child: const _BottomIcon(
                icon: Icons.upload_file,
                label: "Upload",
              ),
            ),
            // 2. Radio
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
            // 3. Home
            GestureDetector(
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const DashboardPage()),
              ),
              child: const _BottomIcon(icon: Icons.home, label: "Home"),
            ),
            // 4. TV (Active)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF5BC0EB),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFF2C3E50), width: 2),
              ),
              child: const Icon(Icons.tv, color: Colors.white, size: 32),
            ),
            // 5. Profile
            GestureDetector(
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              ),
              child: const _BottomIcon(icon: Icons.person, label: "Profile"),
            ),
          ],
        ),
      ),
    );
  }
}

// --- WIDGET: Channel Card ---
class _ChannelCard extends StatelessWidget {
  final String title;
  final String status;
  final String fileName;
  final int colorCode;

  const _ChannelCard({
    required this.title,
    required this.status,
    required this.fileName,
    required this.colorCode,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Play the video
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoPlayerPage(fileName: fileName),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Color(colorCode),
          border: Border.all(color: const Color(0xFF2C3E50), width: 1.5),
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              offset: Offset(3, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // TV Icon
            Icon(
              Icons.tv,
              size: 48,
              color: const Color(0xFF2C3E50).withOpacity(0.8),
            ),
            const SizedBox(height: 15),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 12),

            // Status Badge (Green for Transcribed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green[100], // Light Green background
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF2C3E50), width: 1),
              ),
              child: Text(
                status, // "Transcribed"
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
            ),
          ],
        ),
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
