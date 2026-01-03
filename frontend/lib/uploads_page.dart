import 'dart:io'; // To get file size
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // For Video/Camera
import 'package:file_picker/file_picker.dart'; // For Audio Files
import 'package:intl/intl.dart'; // For Dates
import 'dashboard_page.dart';
import 'profile_page.dart';
import 'video_player_page.dart';
import 'tv_page.dart';
import 'radio_page.dart';

class UploadsPage extends StatefulWidget {
  const UploadsPage({super.key});

  @override
  State<UploadsPage> createState() => _UploadsPageState();
}

class _UploadsPageState extends State<UploadsPage> {
  // 1. SETUP PICKERS
  final ImagePicker _picker = ImagePicker();

  // 2. DATA LIST
  final List<Map<String, String>> myFiles = [
    {
      "title": "Lecture_Math_101.mp4",
      "date": "10 Dec 2025",
      "size": "45 MB",
      "status": "Done",
    },
    {
      "title": "Interview_Session.mp3",
      "date": "08 Dec 2025",
      "size": "12 MB",
      "status": "Transcribing...",
    },
  ];

  // --- LOGIC: HELPER TO FORMAT SIZE ---
  String _getFileSize(File file) {
    int bytes = file.lengthSync();
    double mb = bytes / (1024 * 1024);
    return "${mb.toStringAsFixed(1)} MB";
  }

  // --- LOGIC: PICK VIDEO (Camera or Gallery) ---
  Future<void> _pickVideo(ImageSource source) async {
    Navigator.pop(context); // Close the menu first

    final XFile? video = await _picker.pickVideo(
      source: source,
      maxDuration: const Duration(minutes: 10), // <--- 10 Minute Limit!
    );

    if (video != null) {
      File file = File(video.path);
      String size = _getFileSize(file);
      String date = DateFormat('dd MMM yyyy').format(DateTime.now());

      setState(() {
        myFiles.insert(0, {
          // Add to TOP of list
          "title": video.name, // Real file name
          "date": date,
          "size": size,
          "status": "Transcribing...", // Default status
        });
      });

      _showSuccess("Video added successfully!");
    }
  }

  // --- LOGIC: PICK AUDIO (File Manager) ---
  Future<void> _pickAudio() async {
    Navigator.pop(context); // Close menu

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio, // Only allow Audio files
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      String size = _getFileSize(file);
      String date = DateFormat('dd MMM yyyy').format(DateTime.now());

      setState(() {
        myFiles.insert(0, {
          "title": result.files.single.name,
          "date": date,
          "size": size,
          "status": "Transcribing...",
        });
      });

      _showSuccess("Audio added successfully!");
    }
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }

  // --- LOGIC: DELETE FILE ---
  void _deleteFile(int index) {
    setState(() {
      myFiles.removeAt(index);
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("File deleted successfully.")));
  }

  // --- UI: UPLOAD MENU ---
  // --- UI: UPLOAD MENU ---
  void _showUploadPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled:
          true, // <--- OPTIONAL: Allows it to be taller if needed
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFF2C3E50), width: 2),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        padding: const EdgeInsets.all(24),

        // --- THE FIX IS HERE ---
        // We wrap the Column in SingleChildScrollView so it can scroll!
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Upload New Story",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Choose an option:",
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              const SizedBox(height: 30),

              // OPTION 1: RECORD VIDEO
              _UploadOption(
                icon: Icons.camera_alt_outlined,
                text: "Record Video (Max 10m)",
                onTap: () => _pickVideo(ImageSource.camera),
              ),
              const SizedBox(height: 15),

              // OPTION 2: UPLOAD VIDEO
              _UploadOption(
                icon: Icons.video_library_outlined,
                text: "Upload Video",
                onTap: () => _pickVideo(ImageSource.gallery),
              ),
              const SizedBox(height: 15),

              // OPTION 3: UPLOAD AUDIO
              _UploadOption(
                icon: Icons.audiotrack_outlined,
                text: "Upload Audio (.mp3)",
                onTap: () => _pickAudio(),
              ),

              // Add a little bottom padding for safety
              const SizedBox(height: 20),
            ],
          ),
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
        automaticallyImplyLeading: false,
        title: const Text(
          "My Uploads",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        centerTitle: true,
        shape: const Border(
          bottom: BorderSide(color: Color(0xFF2C3E50), width: 2.0),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUploadPicker(context),
        backgroundColor: const Color(0xFF5BC0EB),
        shape: const CircleBorder(
          side: BorderSide(color: Color(0xFF2C3E50), width: 2),
        ),
        child: const Icon(Icons.add, size: 32, color: Colors.white),
      ),

      body: myFiles.isEmpty
          ? const Center(
              child: Text("No files yet!", style: TextStyle(fontSize: 28)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: myFiles.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    String currentStatus = myFiles[index]["status"]!;
                    String fileName = myFiles[index]["title"]!;

                    if (currentStatus == "Transcribing...") {
                      // SHOW LOADING POPUP
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side: const BorderSide(
                              color: Color(0xFF2C3E50),
                              width: 2,
                            ),
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'assets/images/loading.png',
                                height: 100,
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                "Still Thinking...",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                              const Text(
                                "The AI is watching this video.\nPlease wait a moment!",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                "Okay",
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Color(0xFF5BC0EB),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              VideoPlayerPage(fileName: fileName),
                        ),
                      );
                    }
                  },
                  child: _FileCard(
                    fileName: myFiles[index]["title"]!,
                    date: myFiles[index]["date"]!,
                    size: myFiles[index]["size"]!,
                    status: myFiles[index]["status"]!,
                    color: index % 2 == 0
                        ? const Color(0xFFF9F7F1)
                        : const Color(0xFFE3F2FD),
                    onDelete: () => _deleteFile(index),
                  ),
                );
              },
            ),

      bottomNavigationBar: Container(
        height: 80,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFF2C3E50), width: 2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF5BC0EB),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFF2C3E50), width: 2),
              ),
              child: const Icon(
                Icons.upload_file,
                color: Colors.white,
                size: 32,
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const RadioPage()),
              ),
              child: const _BottomIcon(icon: Icons.radio, label: "Radio"),
            ),
            GestureDetector(
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const DashboardPage()),
              ),
              child: const _BottomIcon(icon: Icons.home, label: "Home"),
            ),
            GestureDetector(
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const TvPage()),
              ),
              child: const _BottomIcon(icon: Icons.tv, label: "TV"),
            ),
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

// --- WIDGET: File Card (No Changes) ---
class _FileCard extends StatelessWidget {
  final String fileName;
  final String date;
  final String size;
  final String status;
  final Color color;
  final VoidCallback onDelete;

  const _FileCard({
    required this.fileName,
    required this.date,
    required this.size,
    required this.status,
    required this.color,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    bool isDone = status == "Done";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: const Color(0xFF2C3E50), width: 1.5),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: Colors.black12, offset: Offset(3, 3), blurRadius: 0),
        ],
      ),
      child: Row(
        children: [
          Icon(
            fileName.endsWith('.mp3') ? Icons.audiotrack : Icons.videocam,
            size: 40,
            color: const Color(0xFF2C3E50),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "$date  •  $size",
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF2C3E50).withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isDone ? Colors.green[100] : Colors.orange[100],
                    border: Border.all(
                      color: const Color(0xFF2C3E50),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDone ? Colors.green[800] : Colors.orange[900],
                    ),
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Color(0xFF2C3E50)),
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: Color(0xFF2C3E50)),
            ),
            onSelected: (value) {
              if (value == 'delete') onDelete();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.redAccent),
                    SizedBox(width: 8),
                    Text(
                      "Delete",
                      style: TextStyle(fontSize: 18, color: Colors.redAccent),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Helpers...
class _UploadOption extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  const _UploadOption({
    required this.icon,
    required this.text,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F7F1),
          border: Border.all(color: const Color(0xFF2C3E50), width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF2C3E50), size: 30),
            const SizedBox(width: 15),
            Text(
              text,
              style: const TextStyle(
                fontSize: 20,
                color: Color(0xFF2C3E50),
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF2C3E50),
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
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
