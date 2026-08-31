/// Coordinates in Degrees.
class CustomLatLng {
  double latitude;
  double longitude;

  CustomLatLng(this.latitude, this.longitude);

  // ==========================================
  // TRACCAR API POSITIONS & SOCKET INTEGRATION
  // ==========================================

  /// Creates a [CustomLatLng] directly from a Traccar position JSON payload (`/api/positions` or `/api/socket`)
  factory CustomLatLng.fromTraccarJson(Map<String, dynamic> json) {
    final double lat =
        double.tryParse(json['latitude']?.toString() ?? '0.0') ?? 0.0;
    final double lng =
        double.tryParse(json['longitude']?.toString() ?? '0.0') ?? 0.0;
    return CustomLatLng(lat, lng);
  }

  /// Converts a list of raw Traccar position JSON objects (`/api/reports/route`) to `List<CustomLatLng>`
  static List<CustomLatLng> parseTraccarPositions(List<dynamic> jsonList) {
    final List<CustomLatLng> coordinates = [];
    for (var item in jsonList) {
      if (item is Map<String, dynamic> &&
          item.containsKey('latitude') &&
          item.containsKey('longitude')) {
        coordinates.add(CustomLatLng.fromTraccarJson(item));
      }
    }
    return coordinates;
  }

  /// Converts [CustomLatLng] back to Traccar API compatible payload format
  Map<String, dynamic> toTraccarJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  @override
  String toString() =>
      'CustomLatLng(latitude: $latitude, longitude: $longitude)';
}
