import 'package:just_audio/just_audio.dart';

class AudioManager {
  // 1. The Singleton Logic
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  // 2. The One and Only Player
  final AudioPlayer _player = AudioPlayer();

  AudioPlayer get player => _player;

  // --- CONFIGURATION ---
  // How many seconds to wait before playing audio?
  // 4 seconds allows the AI to "read ahead" and send text before you hear it.
  static const int syncDelaySeconds = 4;

  // 3. The Play Function
  Future<void> playStation(String url) async {
    try {
      // Force stop whatever was playing before
      if (_player.playing) {
        await _player.stop();
      }

      // Set the new source with headers
      await _player.setAudioSource(
        AudioSource.uri(
          Uri.parse(url),
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
            'Referer': 'https://www.google.com/',
            'Accept': '*/*',
          },
        ),
        // Preload ensures it starts buffering immediately
        preload: true,
      );

      // --- THE SYNC MAGIC ---
      // 1. Explicitly load the stream (start downloading data)
      await _player.load();

      // 2. Wait for X seconds while the AI processes the first sentence.
      // The audio is "paused" here, but the backend is already listening!
      print("⏳ Syncing audio... waiting $syncDelaySeconds seconds...");
      await Future.delayed(Duration(seconds: syncDelaySeconds));

      // 3. NOW play. The user hears "Hello" right as the text "Hello" appears.
      _player.play();
    } catch (e) {
      print("AudioManager Error: $e");
      rethrow;
    }
  }

  // 4. Cleanup
  void dispose() {
    _player.dispose();
  }
}
