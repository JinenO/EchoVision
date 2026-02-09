import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart'; // AI Connection
import '../models/radio_station.dart';
import '../services/radio_service.dart';
import '../services/audio_manager.dart'; // Import your Singleton Manager
// Import your other pages for the bottom bar
import 'dashboard_page.dart';
import 'uploads_page.dart';
import 'tv_page.dart';
import 'profile_page.dart';
import 'radio_schedule_page.dart';

class RadioPage extends StatefulWidget {
  const RadioPage({super.key});

  @override
  State<RadioPage> createState() => _RadioPageState();
}

class _RadioPageState extends State<RadioPage> {
  // --- CONFIGURATION ---
  // Use 127.0.0.1 because of 'adb reverse tcp:8000 tcp:8000'
  static const String _serverIp = '127.0.0.1';
  static const String _wsUrl = 'ws://$_serverIp:8000/ws/radio';

  final RadioService _radioService = RadioService();
  final AudioManager _audioManager = AudioManager();

  // SCROLL CONTROLLER (To auto-scroll the transcript)
  final ScrollController _scrollController = ScrollController();

  List<RadioStation> _stations = [];
  bool _isLoading = true;
  String _selectedFilter = "All";

  // Player State
  RadioStation? _currentStation;
  bool _isPlaying = false;

  // AI Transcription State
  WebSocketChannel? _channel;
  List<String> _transcriptHistory = []; // We keep a LIST of sentences now
  bool _isTranscribing = false;

  @override
  void initState() {
    super.initState();
    _fetchStations();
  }

  @override
  void dispose() {
    _disconnectAI();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchStations() async {
    setState(() => _isLoading = true);
    List<RadioStation> stations = await _radioService.fetchStations(
      category: _selectedFilter,
    );
    setState(() {
      _stations = stations;
      _isLoading = false;
    });
  }

  void _onFilterChanged(String newFilter) {
    if (_selectedFilter != newFilter) {
      setState(() => _selectedFilter = newFilter);
      _fetchStations();
    }
  }

  // --- ROBUST PLAY LOGIC ---
  // --- AUTO-START PLAY LOGIC ---
  Future<void> _playStation(RadioStation station) async {
    // 1. FORCE STOP EVERYTHING (Reset)
    _disconnectAI();
    await _audioManager.player.stop();

    // 2. CHECK: Did the user tap the SAME station to stop it?
    if (_currentStation == station && _isPlaying) {
      setState(() {
        _isPlaying = false;
        _isTranscribing = false;
        // Optional: Leave the text so they can read what they just heard
      });
      return;
    }

    // 3. START NEW STATION & AUTO-START AI
    setState(() {
      _currentStation = station;
      _isPlaying = true;

      // Auto-set this to true so the UI shows the "Stop AI" button immediately
      _isTranscribing = true;

      // Wipe old text
      _transcriptHistory.clear();
      _transcriptHistory.add("Waiting for audio...");
    });

    try {
      // 4. Play Audio
      await _audioManager.playStation(station.url);

      // 5. START AI AUTOMATICALLY (The Magic Line)
      _startTranscription();
    } catch (e) {
      print("Error playing station: $e");
      // If audio fails, we must cancel the AI too
      _disconnectAI();
      setState(() {
        _isPlaying = false;
        _transcriptHistory.add("❌ Error: Could not play station.");
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Cannot play ${station.name}")));
    }
  }
  // --- AI LOGIC (Updated for Scrolling) ---
  void _toggleAI() {
    if (_isTranscribing) {
      _disconnectAI();
    } else {
      _startTranscription();
    }
  }

  void _startTranscription() {
    if (_currentStation == null) return;

    // Note: We don't need setState() here because we already did it in _playStation
    // But we keep the connection logic.

    try {
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      _channel!.sink.add(_currentStation!.url);

      _channel!.stream.listen(
        (message) {
          setState(() {
            _transcriptHistory.add(message);
          });
          // Auto-scroll
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        },
        onError: (e) =>
            setState(() => _transcriptHistory.add("❌ Error: Check Server")),
        onDone: () => setState(() => _isTranscribing = false),
      );
    } catch (e) {
      print("AI Connection Error: $e");
    }
  }

  void _disconnectAI() {
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
    }
    setState(() {
      _isTranscribing = false;
      _transcriptHistory.add("🛑 Transcription Stopped");
    });
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
          "Live Radio",
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
        actions: [
          IconButton(
            icon: const Icon(
              Icons.calendar_month,
              color: Color(0xFF2C3E50),
              size: 28,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RadioSchedulePage(),
                ),
              );
            },
          ),
          const SizedBox(width: 10),
        ],
      ),

      body: Column(
        children: [
          // 1. FILTER BUTTONS
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 15.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _FilterButton(
                  text: "All",
                  isSelected: _selectedFilter == "All",
                  onTap: () => _onFilterChanged("All"),
                ),
                const SizedBox(width: 10),
                _FilterButton(
                  text: "News",
                  isSelected: _selectedFilter == "News",
                  onTap: () => _onFilterChanged("News"),
                ),
                const SizedBox(width: 10),
                _FilterButton(
                  text: "Talk",
                  isSelected: _selectedFilter == "Talk",
                  onTap: () => _onFilterChanged("Talk"),
                ),
              ],
            ),
          ),

          // 2. SCROLLABLE TRANSCRIPT BOX (Replaces the old single-line box)
          // Only shows when there is history or transcription is active
          if (_transcriptHistory.isNotEmpty || _isTranscribing)
            Container(
              height:
                  200, // Fixed height so it doesn't push everything off screen
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.yellowAccent.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "LIVE TRANSCRIPT HISTORY",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(color: Colors.grey),
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: _transcriptHistory.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Text(
                            _transcriptHistory[index],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

          // 3. STATION LIST
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _stations.length,
                    itemBuilder: (context, index) {
                      final station = _stations[index];
                      final isPlayingThis = _currentStation == station;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: isPlayingThis ? Colors.blue[50] : Colors.white,
                          border: Border.all(
                            color: isPlayingThis
                                ? const Color(0xFF5BC0EB)
                                : const Color(0xFF2C3E50),
                            width: isPlayingThis ? 2.5 : 1.5,
                          ),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              offset: Offset(3, 3),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Image.network(
                                station.favicon,
                                errorBuilder: (c, o, s) =>
                                    const Icon(Icons.radio),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    station.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2C3E50),
                                    ),
                                  ),
                                  Text(
                                    station.country,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                isPlayingThis && _isPlaying
                                    ? Icons.pause_circle_filled
                                    : Icons.play_circle_fill,
                                color: const Color(0xFF5BC0EB),
                                size: 40,
                              ),
                              onPressed: () => _playStation(station),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // 4. MINI PLAYER
          if (_currentStation != null)
            Container(
              padding: const EdgeInsets.all(15),
              decoration: const BoxDecoration(
                color: Color(0xFF2C3E50),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.music_note, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Playing: ${_currentStation!.name}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // --- AI BUTTON ---
                  ElevatedButton.icon(
                    onPressed: _toggleAI,
                    icon: Icon(
                      _isTranscribing ? Icons.stop : Icons.closed_caption,
                      size: 18,
                    ),
                    label: Text(_isTranscribing ? "Stop AI" : "Transcribe"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isTranscribing
                          ? Colors.redAccent
                          : const Color(0xFF5BC0EB),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),

      // BOTTOM BAR
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
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const UploadsPage()),
              ),
              child: const _BottomIcon(
                icon: Icons.upload_file,
                label: "Upload",
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF5BC0EB),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFF2C3E50), width: 2),
              ),
              child: const Icon(Icons.radio, color: Colors.white, size: 32),
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

// Helper Widgets
class _FilterButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;
  const _FilterButton({
    required this.text,
    required this.isSelected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2C3E50) : const Color(0xFFF9F7F1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF2C3E50), width: 1.5),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : const Color(0xFF2C3E50),
          ),
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
