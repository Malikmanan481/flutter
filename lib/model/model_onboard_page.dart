import 'dart:ui';

class OnboardPageModel {
  final Color primeColor;
  final Color accentColor;
  final Color nextAccentColor;
  final int pageNumber;
  final String imagePath;
  final String caption;
  final String subhead;
  final String description;

  OnboardPageModel(
    this.primeColor,
    this.accentColor,
    this.nextAccentColor,
    this.pageNumber,
    this.imagePath,
    this.caption,
    this.subhead,
    this.description,
  );

  /// Dynamic JSON Parser (Remote onboarding config or backend settings parsing)
  factory OnboardPageModel.fromJson(Map<String, dynamic> json) {
    return OnboardPageModel(
      _parseColor(json['primeColor'], const Color(0xFF1E88E5)),
      _parseColor(json['accentColor'], const Color(0xFF1565C0)),
      _parseColor(json['nextAccentColor'], const Color(0xFF0D47A1)),
      json['pageNumber'] is int ? json['pageNumber'] : int.tryParse(json['pageNumber']?.toString() ?? '1') ?? 1,
      json['imagePath']?.toString() ?? 'assets/images/onboard_default.png',
      json['caption']?.toString() ?? '',
      json['subhead']?.toString() ?? '',
      json['description']?.toString() ?? '',
    );
  }

  /// Traccar Server API Parser (/api/server endpoint response)
  factory OnboardPageModel.fromTraccarServer(
    Map<String, dynamic> serverJson, {
    required int pageNumber,
    required String imagePath,
    Color defaultPrime = const Color(0xFF1E88E5),
    Color defaultAccent = const Color(0xFF1565C0),
    Color defaultNext = const Color(0xFF0D47A1),
  }) {
    var attributes = serverJson['attributes'] is Map<String, dynamic> ? serverJson['attributes'] : {};

    return OnboardPageModel(
      defaultPrime,
      defaultAccent,
      defaultNext,
      pageNumber,
      imagePath,
      serverJson['title']?.toString() ?? 'GPS Tracking',
      attributes['onboardSubhead']?.toString() ?? 'Traccar Telematics Server',
      attributes['onboardDescription']?.toString() ?? 'Real-time vehicle tracking, geofence management, and instantaneous push alerts.',
    );
  }

  Map<String, dynamic> toJson() => {
        'primeColor': primeColor.value,
        'accentColor': accentColor.value,
        'nextAccentColor': nextAccentColor.value,
        'pageNumber': pageNumber,
        'imagePath': imagePath,
        'caption': caption,
        'subhead': subhead,
        'description': description,
      };

  /// Hex string (#FF5722) ya integer ko Flutter Color object me convert karne ke liye helper
  static Color _parseColor(dynamic val, Color fallback) {
    if (val == null) return fallback;
    if (val is int) return Color(val);
    if (val is String) {
      String hex = val.replaceAll('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      int? colorInt = int.tryParse(hex, radix: 16);
      if (colorInt != null) return Color(colorInt);
    }
    return fallback;
  }
}
