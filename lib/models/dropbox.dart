// lib/models/dropbox.dart
class Dropbox {
  final int id;
  final String locationName;
  final double latitude;
  final double longitude;

  Dropbox({
    required this.id,
    required this.locationName,
    required this.latitude,
    required this.longitude,
  });

  factory Dropbox.fromJson(Map<String, dynamic> json) {
    return Dropbox(
      id: json['id'],
      locationName: json['location_name'],
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
    );
  }
}