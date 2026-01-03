import 'package:flutter/material.dart';
import 'dart:async';
import '../models/radio_station.dart';
import '../services/radio_service.dart';
import 'radio_player_page.dart'; // Make sure this import path is correct for your project structure!

class RadioSchedulePage extends StatefulWidget {
  const RadioSchedulePage({super.key});

  @override
  State<RadioSchedulePage> createState() => _RadioSchedulePageState();
}

class _RadioSchedulePageState extends State<RadioSchedulePage> {
  final RadioService _radioService = RadioService();
  List<RadioStation> _stations = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadStations();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadStations() async {
    final stations = await _radioService.fetchStations(category: 'All');
    setState(() {
      _stations = stations;
    });
  }

  String _getLocalTime(String timeZone) {
    DateTime now = DateTime.now().toUtc();
    int offsetHours = 0;

    if (timeZone == 'Europe/London' || timeZone == 'Europe/Dublin') {
      offsetHours = 0;
    } else if (timeZone == 'America/New_York') {
      offsetHours = -5;
    } else if (timeZone == 'Asia/Hong_Kong') {
      offsetHours = 8;
    }

    DateTime localTime = now.add(Duration(hours: offsetHours));
    String hour = localTime.hour.toString().padLeft(2, '0');
    String minute = localTime.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  String _getStatus(RadioStation station) {
    String timeStr = _getLocalTime(station.timeZone);
    int hour = int.parse(timeStr.split(":")[0]);

    if (station.name.contains("Sky News") ||
        station.name.contains("BBC World") ||
        station.name.contains("NPR")) {
      return "🔴 Live News Coverage";
    }

    if (hour >= 6 && hour < 10) return "☕ Morning Briefing";
    if (hour >= 10 && hour < 13) return "🗣️ Live Debate / Talk";
    if (hour >= 13 && hour < 17) return "🌍 Afternoon Stories";
    if (hour >= 17 && hour < 20) return "📉 Evening News Roundup";
    if (hour >= 20 && hour <= 23) return "🎙️ Late Night Discussion";
    return "💤 Overnight / Replays";
  }

  Color _getStatusColor(String status) {
    if (status.contains("Live") || status.contains("Debate"))
      return Colors.green[100]!;
    if (status.contains("Morning") || status.contains("Evening"))
      return Colors.orange[100]!;
    return Colors.grey[300]!;
  }

  // --- NEW: Function to open player ---
  void _playStation(RadioStation station) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RadioPlayerPage(station: station),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Station Guide",
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2C3E50),
        elevation: 0,
        centerTitle: true,
      ),
      body: _stations.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _stations.length,
              itemBuilder: (context, index) {
                final station = _stations[index];
                final localTime = _getLocalTime(station.timeZone);
                final status = _getStatus(station);
                final statusColor = _getStatusColor(status);

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Favicon
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Image.network(
                              station.favicon,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.radio, color: Colors.grey),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Text Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                station.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: Colors.blueGrey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Local Time: $localTime",
                                    style: const TextStyle(
                                      color: Colors.blueGrey,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // --- NEW: Play Button on the Schedule ---
                        IconButton(
                          onPressed: () => _playStation(station),
                          icon: const Icon(
                            Icons.play_arrow_rounded,
                            size: 32,
                            color: Color(0xFF5BC0EB),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
