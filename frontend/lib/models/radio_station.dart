class RadioStation {
  final String name;
  final String url;
  final String country;
  final String favicon;
  final String timeZone; // Add this! (e.g., 'Europe/London')

  RadioStation({
    required this.name,
    required this.url,
    required this.country,
    required this.favicon,
    this.timeZone = 'UTC', // Default to UTC if not known
  });

  factory RadioStation.fromJson(Map<String, dynamic> json) {
    return RadioStation(
      name: json['name'] ?? 'Unknown',
      url: json['url'] ?? '',
      country: json['country'] ?? 'Unknown',
      favicon: json['favicon'] ?? '',
      // We will set timezones manually in the service, so just default here
      timeZone: 'UTC',
    );
  }
}
