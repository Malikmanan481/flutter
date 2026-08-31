//https://github.com/googlemaps/android-maps-utils

import 'dart:math';

class MathUtil {
  static const double EARTH_RADIUS = 6371009.0; // Earth radius in meters

  static num toRadians(num degrees) => degrees / 180.0 * pi;

  static num toDegrees(num rad) => rad * (180.0 / pi);

  /// Wraps the given value into the inclusive-exclusive interval between min
  /// and max.
  /// @param n   The value to wrap.
  /// @param min The minimum.
  /// @param max The maximum.
  static num wrap(num n, num min, num max) =>
      (n >= min && n < max) ? n : (mod(n - min, max - min) + min);

  /// Returns haversine(angle-in-radians).
  /// hav(x) == (1 - cos(x)) / 2 == sin(x / 2)^2.
  static num hav(num x) => sin(x * 0.5) * sin(x * 0.5);

  /// Returns hav() of distance from (lat1, lng1) to (lat2, lng2) on the unit
  /// sphere.
  static num havDistance(num lat1, num lat2, num dLng) =>
      hav(lat1 - lat2) + hav(dLng) * cos(lat1) * cos(lat2);

  /// Computes inverse haversine. Has good numerical stability around 0.
  /// arcHav(x) == acos(1 - 2 * x) == 2 * asin(sqrt(x)).
  /// The argument must be in [0, 1], and the result is positive.
  static num arcHav(num x) => 2 * asin(sqrt(x));

  /// Returns the non-negative remainder of x / m.
  /// @param x The operand.
  /// @param m The modulus.
  static num mod(num x, num m) => ((x % m) + m) % m;

  // ==========================================
  // TRACCAR TELEMATICS & POSITIONS MATH HELPERS
  // ==========================================

  /// Computes distance in meters between two lat/lng coordinates (Traccar /api/positions)
  static double computeDistanceBetween(
      num fromLat, num fromLng, num toLat, num toLng) {
    num fromLatRad = toRadians(fromLat);
    num fromLngRad = toRadians(fromLng);
    num toLatRad = toRadians(toLat);
    num toLngRad = toRadians(toLng);
    num dLat = fromLatRad - toLatRad;
    num dLng = fromLngRad - toLngRad;

    num havD = havDistance(fromLatRad, toLatRad, dLng);
    return (2 * EARTH_RADIUS * asin(sqrt(havD))).toDouble();
  }

  /// Calculates bearing/heading angle (0° to 360°) between two coordinates
  static double computeBearing(
      num fromLat, num fromLng, num toLat, num toLng) {
    num fromLatRad = toRadians(fromLat);
    num fromLngRad = toRadians(fromLng);
    num toLatRad = toRadians(toLat);
    num toLngRad = toRadians(toLng);
    num dLng = toLngRad - fromLngRad;

    num y = sin(dLng) * cos(toLatRad);
    num x = cos(fromLatRad) * sin(toLatRad) -
        sin(fromLatRad) * cos(toLatRad) * cos(dLng);

    return wrap(toDegrees(atan2(y, x)), 0, 360).toDouble();
  }

  /// Converts speed from Knots (Traccar default speed unit) to KM/H
  static double knotsToKmh(num knots) {
    return (knots * 1.852);
  }

  /// Converts speed from Knots (Traccar default speed unit) to MPH
  static double knotsToMph(num knots) {
    return (knots * 1.15078);
  }
}
