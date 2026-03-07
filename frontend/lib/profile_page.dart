import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'widgets.dart';
import 'login_page.dart';
import 'dashboard_page.dart';
import 'edit_profile_page.dart';
import 'uploads_page.dart';
import 'tv_page.dart';
import 'radio_page.dart';
import 'api_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Variables to hold your database data
  bool _isLoading = true;
  String _username = "Loading...";
  String _email = "Loading...";
  String _birthday = "Loading...";
  String _gender = "Loading...";
  String _profilePicture = "default_avatar.png";

  @override
  void initState() {
    super.initState();
    _loadProfileData(); // Fetch data when the page opens
  }

  Future<void> _loadProfileData() async {
    try {
      final data = await ApiService.getUserProfile();

      if (data != null && mounted) {
        setState(() {
          _username = data["username"]?.toString() ?? "Unknown User";
          _email = data["email"]?.toString() ?? "No Email";
          _gender = data["gender"]?.toString() ?? "Not Specified";
          _profilePicture =
              data["profile_picture"]?.toString() ?? "default_avatar.png";

          // Bulletproof Birthday Parsing
          if (data["birthday"] != null) {
            try {
              DateTime parsedDate = DateTime.parse(data["birthday"].toString());
              _birthday = DateFormat('dd MMMM yyyy').format(parsedDate);
            } catch (dateError) {
              print("Date Parsing Error: $dateError");
              _birthday = data["birthday"]
                  .toString(); // Fallback to raw string if parsing fails
            }
          } else {
            _birthday = "No Birthday Set";
          }

          _isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _username = "Error: Data is null";
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print("CRASH AVOIDED: $e");
      if (mounted) {
        setState(() {
          _username = "Something went wrong";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // --- HEADER ---
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 80,
        shape: const Border(
          bottom: BorderSide(color: Color(0xFF2C3E50), width: 2.0),
        ),
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          "My Profile",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
      ),

      // --- BODY ---
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 20,
                ),
                child: Column(
                  children: [
                    // --- PROFILE PICTURE ---
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF2C3E50),
                          width: 3,
                        ),
                      ),
                      child: ClipOval(
                        child: Transform.scale(
                          scale: 1.3,
                          child: _profilePicture == "default_avatar.png"
                              ? Image.asset(
                                  'assets/images/profile.png',
                                  fit: BoxFit.cover,
                                )
                              : Image.network(
                                  _profilePicture,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Image.asset(
                                        'assets/images/profile.png',
                                        fit: BoxFit.cover,
                                      ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // --- DYNAMIC USERNAME ---
                    Text(
                      _username,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // --- DYNAMIC INFO BOX ---
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: const Color(0xFF2C3E50),
                          width: 2,
                        ),
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
                          _ProfileRow(icon: Icons.email_outlined, text: _email),
                          const Divider(color: Color(0xFF2C3E50), thickness: 1),
                          const _ProfileRow(
                            icon: Icons.remove_red_eye_outlined,
                            text: "•••••••••••",
                          ),
                          const Divider(color: Color(0xFF2C3E50), thickness: 1),
                          _ProfileRow(
                            icon: Icons.calendar_today,
                            text: _birthday,
                          ),
                          const Divider(color: Color(0xFF2C3E50), thickness: 1),
                          _ProfileRow(
                            icon: Icons.person_outline,
                            text: _gender,
                          ),
                          const Divider(color: Color(0xFF2C3E50), thickness: 1),

                          // Logout Button
                          InkWell(
                            onTap: () {
                              ApiService.currentToken = null;
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginPage(),
                                ),
                                (route) => false,
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12.0),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.logout,
                                    color: Colors.redAccent,
                                    size: 26,
                                  ),
                                  SizedBox(width: 16),
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

                    // Edit Profile Button
                    SizedBox(
                      width: 200,
                      child: SketchyButton(
                        text: "Edit Profile",
                        onTap: () {
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

      // --- BOTTOM NAVIGATION BAR ---
      bottomNavigationBar: Container(
        height: 80,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFF2C3E50), width: 2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UploadsPage()),
                );
              },
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.upload_file, color: Color(0xFF2C3E50), size: 28),
                  Text(
                    "Upload",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const RadioPage()),
                );
              },
              child: const _BottomIcon(icon: Icons.radio, label: "Radio"),
            ),
            GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const DashboardPage()),
                );
              },
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.home, color: Color(0xFF2C3E50), size: 28),
                  Text(
                    "Home",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF5BC0EB),
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
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 20, color: Color(0xFF2C3E50)),
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
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
