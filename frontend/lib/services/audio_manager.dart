import 'package:just_audio/just_audio.dart';

class AudioManager {
  // 1. The Singleton Logic (Ensures only ONE instance exists)
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  // 2. The One and Only Player
  final AudioPlayer _player = AudioPlayer();

  // Getter so we can access the player from other pages
  AudioPlayer get player => _player;

  // 3. The Play Function
  Future<void> playStation(String url) async {
    try {
      // Force stop whatever was playing before
      if (_player.playing) {
        await _player.stop();
      }

      // Set the new source with the "Fake Browser" headers
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
      );

      // Start playing
      _player.play();
    } catch (e) {
      print("AudioManager Error: $e");
      rethrow; // Pass error to the UI to handle
    }
  }

  // 4. Cleanup (Only call this when closing the ENTIRE app)
  void dispose() {
    _player.dispose();
  }
}
