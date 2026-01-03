import 'package:flutter/material.dart';

class VideoPlayerPage extends StatelessWidget {
  final String fileName;

  const VideoPlayerPage({super.key, required this.fileName});

  @override
  Widget build(BuildContext context) {
    bool isAudio = fileName.endsWith('.mp3');

    return Scaffold(
      backgroundColor: Colors.white,

      // --- HEADER ---
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2C3E50)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isAudio ? "Now Listening" : "Now Watching",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2C3E50),
          ),
        ),
        centerTitle: true,
      ),

      body: Column(
        children: [
          // --- 1. MEDIA PLAYER AREA ---
          Container(
            height: 250,
            width: double.infinity,
            color: isAudio
                ? const Color(0xFFF9F7F1)
                : Colors.black, // Cream for Audio, Black for Video
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isAudio) ...[
                  // AUDIO VISUALS (Waveform Icon)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.graphic_eq,
                        size: 80,
                        color: Color(0xFF5BC0EB),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Audio Playing...",
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // VIDEO VISUALS (Play Icon)
                  const Icon(
                    Icons.play_circle_fill,
                    color: Colors.white,
                    size: 60,
                  ),
                ],

                // File Name Label
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: Text(
                    fileName,
                    style: TextStyle(
                      color: isAudio ? const Color(0xFF2C3E50) : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Progress Bar
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(height: 4, color: Colors.redAccent),
                ),
              ],
            ),
          ),

          // --- 2. TRANSCRIPT SECTION ---
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFF2C3E50), width: 2),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Live Transcript",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2C3E50),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5BC0EB),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "AI Active",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // FAKE TRANSCRIPT
                    Text(
                      "00:01 - [Start]\n\n"
                      "00:05 - Speaker: This is a demo of the $fileName.\n\n"
                      "00:12 - Speaker: The AI is currently generating captions for this file in real-time.\n\n"
                      "00:20 - [Sound Effect]\n\n"
                      "00:25 - Speaker: EchoVision makes accessibility easy and fun!",
                      style: TextStyle(
                        fontSize: 20,
                        color: const Color(0xFF2C3E50),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
