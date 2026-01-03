import 'package:flutter/material.dart';
import '../models/radio_station.dart';
import '../services/radio_service.dart';
import 'radio_player_page.dart';
import 'dashboard_page.dart';
import 'uploads_page.dart';
import 'tv_page.dart';
import 'profile_page.dart';
import 'radio_schedule_page.dart'; // Ensure this is imported

class RadioPage extends StatefulWidget {
  const RadioPage({super.key});

  @override
  State<RadioPage> createState() => _RadioPageState();
}

class _RadioPageState extends State<RadioPage> {
  final RadioService _radioService = RadioService();
  List<RadioStation> _stations = [];
  bool _isLoading = true;
  String _selectedFilter = "All";

  @override
  void initState() {
    super.initState();
    _fetchStations();
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

  void _openPlayer(RadioStation station) {
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
        // --- ADDED THIS SECTION ---
        actions: [
          IconButton(
            icon: const Icon(
              Icons.calendar_month,
              color: Color(0xFF2C3E50),
              size: 28,
            ),
            tooltip: "Station Schedule",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RadioSchedulePage(),
                ),
              );
            },
          ),
          const SizedBox(width: 10), // Small padding for right alignment
        ],
        // --------------------------
      ),

      body: Column(
        children: [
          // FILTER BUTTONS
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

          // STATION LIST
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _stations.length,
                    // ... inside ListView.builder ...
                    itemBuilder: (context, index) {
                      final station = _stations[index];

                      // 1. REMOVE the outer GestureDetector
                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: const Color(0xFF2C3E50),
                            width: 1.5,
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
                            // Favicon (Non-clickable)
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: station.favicon.isNotEmpty
                                  ? Image.network(
                                      station.favicon,
                                      errorBuilder: (c, o, s) =>
                                          const Icon(Icons.radio),
                                    )
                                  : const Icon(Icons.radio, size: 30),
                            ),
                            const SizedBox(width: 15),

                            // Text Info (Non-clickable)
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

                            // 2. ONLY THIS BUTTON IS CLICKABLE NOW
                            IconButton(
                              icon: const Icon(
                                Icons
                                    .play_circle_fill, // Filled icon looks more "clickable"
                                color: Color(
                                  0xFF5BC0EB,
                                ), // Blue color to stand out
                                size: 40, // Made it bigger and easier to hit
                              ),
                              onPressed: () =>
                                  _openPlayer(station), // Action happens here!
                            ),
                          ],
                        ),
                      );
                    },
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

// Reused components
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
