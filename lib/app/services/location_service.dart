import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';

/// GPS + reverse-geocoding helper. Returns a value object; the caller
/// decides what to persist. All lookups happen on-device.
class LocatedPlace {
  final double lat;
  final double lng;
  final String city;
  final String country;

  const LocatedPlace({
    required this.lat,
    required this.lng,
    required this.city,
    required this.country,
  });
}

class LocationService {
  /// Current position → coordinates + placemark. Times out instead of
  /// hanging (the old splash blocker).
  Future<LocatedPlace?> current({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: timeout,
      );

      String city = '', country = '';
      try {
        final marks = await geo
            .placemarkFromCoordinates(pos.latitude, pos.longitude)
            .timeout(const Duration(seconds: 6));
        if (marks.isNotEmpty) {
          city =
              marks.first.locality ?? marks.first.subAdministrativeArea ?? '';
          country = marks.first.country ?? '';
        }
      } catch (_) {
        // Placemark lookup can fail offline — coords still work for prayer.
      }
      return LocatedPlace(
        lat: pos.latitude,
        lng: pos.longitude,
        city: city,
        country: country,
      );
    } catch (_) {
      return null;
    }
  }

  /// Manual entry — geocode a city name typed by the user.
  Future<LocatedPlace?> fromCityName(String name) async {
    try {
      final locations = await geo
          .locationFromAddress(name)
          .timeout(const Duration(seconds: 8));
      if (locations.isEmpty) return null;
      final l = locations.first;
      String city = name.trim(), country = '';
      try {
        final marks = await geo
            .placemarkFromCoordinates(l.latitude, l.longitude)
            .timeout(const Duration(seconds: 6));
        if (marks.isNotEmpty) {
          city = marks.first.locality ?? city;
          country = marks.first.country ?? '';
        }
      } catch (_) {}
      return LocatedPlace(
        lat: l.latitude,
        lng: l.longitude,
        city: city,
        country: country,
      );
    } catch (_) {
      return null;
    }
  }
}
