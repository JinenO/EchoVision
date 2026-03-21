import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';
import '../models/radio_station.dart';
import '../services/radio_service.dart';
import '../services/audio_manager.dart';
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
  static const String _serverIp = '127.0.0.1';
  static const String _wsUrl = 'ws://$_serverIp:8000/ws/radio';

  final RadioService _radioService = RadioService();
  final AudioManager _audioManager = AudioManager();
  final ScrollController _scrollController = ScrollController();

  List<RadioStation> _stations = [];
  bool _isLoading = true;
  String _selectedFilter = "All";

  RadioStation? _currentStation;
  bool _isPlaying = false;
  bool _isBuffering = false; // <--- NEW: Tracks network drops
  WebSocketChannel? _channel;

  List<String> _transcriptHistory = [];
  String _liveCaption = "";
  bool _isTranscribing = false;

  double _syncDelaySeconds = 3.0;
  List<Map<String, dynamic>> _subtitleQueue = [];

  final Stopwatch _audioStopwatch = Stopwatch();
  Timer? _syncTimer;

  @override
  void initState() {
    super.initState();
    _fetchStations();
    _loadSavedSyncDelay();

    // 1. Listen exactly to what the Android Audio Player is doing
    _audioManager.player.playerStateStream.listen((state) {
      if (!mounted) return;

      setState(() {
        _isPlaying = state.playing;
        // If the internet drops, tell the UI we are buffering!
        _isBuffering =
            (state.processingState == ProcessingState.buffering ||
            state.processingState == ProcessingState.loading);
      });

      // The stopwatch ONLY ticks if audio is physically coming out of the speakers
      if (state.playing && state.processingState == ProcessingState.ready) {
        _audioStopwatch.start();
      } else {
        _audioStopwatch.stop();
      }
    });

    _syncTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _processSubtitleQueue();
    });
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _audioStopwatch.stop();
    _disconnectAI();
    _scrollController.dispose();
    super.dispose();
  }

  // --- THE BULLETPROOF QUEUE PROCESSOR ---
  void _processSubtitleQueue() {
    if (!_isTranscribing || _subtitleQueue.isEmpty) return;

    // How much audio has actually played on this device
    double currentAudioTime = _audioStopwatch.elapsedMilliseconds / 1000.0;
    bool uiNeedsUpdate = false;

    // Pop the text ONLY when the Audio Time overtakes the (Arrival Time + Slider Delay)
    // This makes it completely immune to internet drops!
    while (_subtitleQueue.isNotEmpty &&
        currentAudioTime >= _subtitleQueue.first['time'] + _syncDelaySeconds) {
      var caption = _subtitleQueue.removeAt(0);

      if (caption['isFinal'] == true) {
        _transcriptHistory.add(caption['text']);
        _liveCaption = "";
        uiNeedsUpdate = true;
      } else {
        _liveCaption = caption['text'];
        uiNeedsUpdate = true;
      }
    }

    if (uiNeedsUpdate && mounted) {
      setState(() {});

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 100),
            curve: Curves.linear,
          );
        }
      });
    }
  }

  Future<void> _loadSavedSyncDelay() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _syncDelaySeconds = prefs.getDouble('saved_sync_delay') ?? 3.0;
    });
  }

  Future<void> _saveSyncDelay(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('saved_sync_delay', value);
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

  // --- THE PERFECTED PLAY/STOP LOGIC ---
  Future<void> _playStation(RadioStation station) async {
    bool wasPlayingThis = (_currentStation == station && _isPlaying);

    // 1. Always Hard-Stop the audio and AI first
    _disconnectAI();
    await _audioManager.player.stop();

    // 2. If they just wanted to stop the current station, clear UI and exit!
    if (wasPlayingThis) {
      setState(() {
        _currentStation = null;
      });
      return;
    }

    // 3. Otherwise, set up the new station
    setState(() {
      _currentStation = station;
      _isPlaying = true;
      _isTranscribing = true;
      _transcriptHistory.clear();
      _liveCaption = "";
      _transcriptHistory.add("Connecting to AI...");
    });

    try {
      await _audioManager.playStation(station.url);
      _startTranscription();
    } catch (e) {
      print("Error playing station: $e");
      _disconnectAI();
      setState(() {
        _isPlaying = false;
        _currentStation = null;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Cannot play ${station.name}")));
    }
  }

  void _startTranscription() {
    if (_currentStation == null) return;

    _audioStopwatch.reset();
    _subtitleQueue.clear();

    try {
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      _channel!.sink.add(_currentStation!.url);

      _channel!.stream.listen(
        (message) {
          if (!mounted || !_isTranscribing) return;

          try {
            final data = jsonDecode(message);

            // Ignore Python's time completely! Tag with Flutter's local arrival time.
            double arrivalTime = _audioStopwatch.elapsedMilliseconds / 1000.0;

            if (data.containsKey('audio_time') ||
                data.containsKey('text') ||
                data.containsKey('partial')) {
              _subtitleQueue.add({
                'time': arrivalTime, // <-- Local Time Tag
                'isFinal': data['is_final'] ?? false,
                'text': data['is_final'] ? data['text'] : data['partial'],
              });
            }
          } catch (e) {
            setState(() {
              if (message == "[[MUSIC_MODE]]") {
                _transcriptHistory.add("🎵 Playing Music...");
              } else {
                _transcriptHistory.add(message);
              }
              _liveCaption = "";
            });
          }
        },
        onError: (e) {
          if (_isTranscribing)
            setState(() => _transcriptHistory.add("❌ Error: Check Server"));
        },
        onDone: () {
          if (mounted && _channel != null) {
            setState(() => _isTranscribing = false);
          }
        },
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
      _liveCaption = "";
      _transcriptHistory.clear();
      _subtitleQueue.clear();
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

          if (_isTranscribing)
            Column(
              children: [
                Container(
                  height: 200,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.yellowAccent.withOpacity(0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "LIVE TRANSCRIPT",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 10,
                              letterSpacing: 2,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // Optional: Show queue size for debugging
                          // Text("${_subtitleQueue.length} words queued", style: TextStyle(color: Colors.grey, fontSize: 10)),
                        ],
                      ),
                      const Divider(color: Colors.grey),
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          // Add 1 extra slot for either the live caption OR the buffering message
                          itemCount:
                              _transcriptHistory.length +
                              (_liveCaption.isNotEmpty || _isBuffering ? 1 : 0),
                          itemBuilder: (context, index) {
                            // Render the history lines normally
                            if (index < _transcriptHistory.length) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 2.0,
                                ),
                                child: Text(
                                  _transcriptHistory[index],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              );
                            }

                            // If we are at the bottom, show Buffering OR Live Text
                            if (_isBuffering) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 2.0),
                                child: Text(
                                  "[Buffering network connection...]",
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 16,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              );
                            } else if (_liveCaption.isNotEmpty) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 2.0,
                                ),
                                child: Text(
                                  _liveCaption,
                                  style: const TextStyle(
                                    color: Colors.yellowAccent,
                                    fontSize: 16,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: Row(
                    children: [
                      const Icon(Icons.timer, color: Colors.grey, size: 18),
                      const SizedBox(width: 5),
                      Text(
                        "Sync: ${_syncDelaySeconds.toStringAsFixed(1)}s",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          value: _syncDelaySeconds,
                          min: 0.0,
                          max: 20.0,
                          divisions: 40,
                          activeColor: const Color(0xFF5BC0EB),
                          inactiveColor: Colors.grey[300],
                          onChanged: (value) {
                            setState(() {
                              _syncDelaySeconds = value;
                            });
                          },
                          onChangeEnd: (value) {
                            _saveSyncDelay(value);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

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
                                    ? Icons
                                          .stop_circle // <--- Clear STOP Icon
                                    : Icons.play_circle_fill,
                                color: isPlayingThis
                                    ? Colors.redAccent
                                    : const Color(0xFF5BC0EB),
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
                  IconButton(
                    icon: const Icon(
                      Icons.stop_circle, // <--- Clear STOP Icon
                      color: Colors.redAccent,
                      size: 40,
                    ),
                    onPressed: () => _playStation(_currentStation!),
                  ),
                ],
              ),
            ),
        ],
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
