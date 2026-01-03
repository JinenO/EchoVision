import '../models/radio_station.dart';

class RadioService {
  // --- 1. NEWS STATIONS (Reporting & Headlines) ---
  final List<RadioStation> _newsStations = [
    RadioStation(
      name: "BBC World Service",
      url: "http://stream.live.vc.bbcmedia.co.uk/bbc_world_service",
      country: "United Kingdom",
      favicon:
          "https://upload.wikimedia.org/wikipedia/commons/thumb/f/fd/BBC_World_Service_Logo_2019.svg/1200px-BBC_World_Service_Logo_2019.svg.png",
      timeZone: "Europe/London"
    ),
    RadioStation(
      name: "Sky News Radio",
      url: "https://radio.canstream.co.uk:8075/live.mp3",
      country: "United Kingdom",
      favicon: "https://news.sky.com/assets/images/sky-news-logo.png",
      timeZone: "Europe/London"
    ),
    RadioStation(
      name: "NPR 24/7 News",
      url: "https://npr-ice.streamguys1.com/live.mp3",
      country: "USA",
      favicon: "https://media.npr.org/chrome/news/nprlogo_138x46.png",
      timeZone: "America/New_York"
    ),
    RadioStation(
      name: "RTHK Radio 3",
      url: "https://stm.rthk.hk/radio3",
      country: "Hong Kong",
      favicon:
          "https://upload.wikimedia.org/wikipedia/en/thumb/5/5e/RTHK_Radio_3_logo.svg/1200px-RTHK_Radio_3_logo.svg.png",
      timeZone: "Asia/Hong_Kong"
    ),
  ];

  // --- 2. TALK STATIONS (Debate, Opinion & Discussion) ---
  final List<RadioStation> _talkStations = [
    RadioStation(
      name: "LBC UK (Debate)",
      url: "https://media-ice.musicradio.com/LBCUKMP3",
      country: "United Kingdom",
      favicon:
          "https://upload.wikimedia.org/wikipedia/en/thumb/9/94/LBC_Logo_2014.png/250px-LBC_Logo_2014.png",
      timeZone: "Europe/London"
    ),
    RadioStation(
      name: "TalkRadio UK",
      url: "https://radio.canstream.co.uk:8075/live.mp3",
      country: "United Kingdom",
      favicon:
          "https://upload.wikimedia.org/wikipedia/en/thumb/8/87/TalkRadio_logo_2022.svg/1200px-TalkRadio_logo_2022.svg.png",
      timeZone: "Europe/London"
    ),
    RadioStation(
      name: "RTE Radio 1",
      url: "https://icecast2.rte.ie/radio1",
      country: "Ireland",
      favicon:
          "https://upload.wikimedia.org/wikipedia/commons/thumb/e/e3/RT%C3%89_Radio_1_logo.svg/1200px-RT%C3%89_Radio_1_logo.svg.png",
      timeZone: "Europe/Dublin"
    ),
  ];

  // --- 3. FETCH LOGIC (Returns the correct list) ---
  Future<List<RadioStation>> fetchStations({String category = 'All'}) async {
    // Artificial delay to mimic API loading
    await Future.delayed(const Duration(milliseconds: 300));

    if (category == 'News') {
      return _newsStations;
    } else if (category == 'Talk') {
      return _talkStations;
    } else {
      // If 'All', combine both lists so user sees everything
      return [..._newsStations, ..._talkStations];
    }
  }
}
