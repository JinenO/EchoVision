import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/radio_station.dart';
import '../services/audio_manager.dart'; // Import the new manager

class RadioPlayerPage extends StatefulWidget {
  final RadioStation station;

  const RadioPlayerPage({super.key, required this.station});

  @override
  State<RadioPlayerPage> createState() => _RadioPlayerPageState();
}

class _RadioPlayerPageState extends State<RadioPlayerPage> {
  // Use the Global Manager instead of creating a new player
  final AudioManager _audioManager = AudioManager();

  bool _isPlaying = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initAudio();

    // Listen to the global player's state
    // We listen to the Stream because the player is managed outside this page
    _audioManager.player.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
          // If it's buffering, show loading; otherwise, show play/pause
          _isLoading =
              state.processingState == ProcessingState.buffering ||
              state.processingState == ProcessingState.loading;
        });
      }
    });
  }

  Future<void> _initAudio() async {
    try {
      setState(() => _isLoading = true);

      // Tell the Manager to play this station
      await _audioManager.playStation(widget.station.url);
    } catch (e) {
      print("Error loading audio: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Could not connect to ${widget.station.name}"),
            backgroundColor: Colors.redAccent,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    // IMPORTANT: We DO NOT dispose the player here anymore!
    // We just leave the page. The audio can keep playing (Radio style),
    // or you can stop it if you prefer: _audioManager.player.stop();
    super.dispose();
  }

  // Toggle Play/Pause using the Manager
  void _togglePlay() {
    if (_isPlaying) {
      _audioManager.player.stop();
    } else {
      _audioManager.player.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2C3E50)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Now Listening",
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      body: Column(
        children: [
          // VISUALIZER AREA
          Container(
            height: 300,
            width: double.infinity,
            color: const Color(0xFFF9F7F1),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _togglePlay, // Tap icon to toggle
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF2C3E50),
                        width: 2,
                      ),
                      color: Colors.white,
                    ),
                    // Show Loading Spinner OR Play/Pause Icon
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            size: 80,
                            color: const Color(0xFF5BC0EB),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    widget.station.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ),
                Text(
                  widget.station.country,
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          ),

          // TRANSCRIPT AREA
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Live Captions",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Connecting to AI Transcription service...",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
