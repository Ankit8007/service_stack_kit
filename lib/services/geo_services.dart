import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' as Math;


class GeoServices {
  /// Get [Placemark] from [LatLng]
  static Future<Placemark?> getPlaceMarkFromLatLng(LatLng latLng) async {
    try {
      final placeMarks = await placemarkFromCoordinates(latLng.latitude, latLng.longitude);
      return placeMarks.isNotEmpty ? placeMarks.first : null;
    } catch (e) {
      print('Error in getPlacemarkFromLatLng: $e');
      return null;
    }
  }

  /// Get [LatLng] from address string
  static Future<LatLng?> getLatLngFromAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        return LatLng(loc.latitude, loc.longitude);
      }
    } catch (e) {
      print('Error in getLatLngFromAddress: $e');
    }
    return null;
  }


  /// Format a readable address from [Placemark]
  static String formatAddress(Placemark place) {
    return [
      place.name,
      place.subLocality,
      place.locality,
      place.administrativeArea,
      place.country,
      place.postalCode,
    ].where((e) => e != null && e.isNotEmpty).join(', ');
  }

  /// Calculate distance in meters between two coordinates
  static double calculateDistance(LatLng from, LatLng to) {
    return Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
  }





  /// Get Placemark from LatLng
  static Future<Placemark?> getPlacemarkFromLatLng(LatLng latLng) async {
    try {
      final placemarks = await placemarkFromCoordinates(latLng.latitude, latLng.longitude);
      return placemarks.isNotEmpty ? placemarks.first : null;
    } catch (e) {
      print('Error in getPlacemarkFromLatLng: $e');
      return null;
    }
  }





  /// Calculate the bearing (direction in degrees) between two points
  static double calculateBearing(LatLng from, LatLng to) {
    final lat1 = _degToRad(from.latitude);
    final lon1 = _degToRad(from.longitude);
    final lat2 = _degToRad(to.latitude);
    final lon2 = _degToRad(to.longitude);

    final dLon = lon2 - lon1;
    final y = Math.sin(dLon) * Math.cos(lat2);
    final x = Math.cos(lat1) * Math.sin(lat2) -
        Math.sin(lat1) * Math.cos(lat2) * Math.cos(dLon);
    return (_radToDeg(Math.atan2(y, x)) + 360) % 360;
  }

  /// Check if two coordinates are within a given radius (in meters)
  static bool isWithinRadius(LatLng point1, LatLng point2, double radiusInMeters) {
    final distance = calculateDistance(point1, point2);
    return distance <= radiusInMeters;
  }

  /// Get midpoint between two coordinates
  static LatLng getMidPoint(LatLng a, LatLng b) {
    return LatLng(
      (a.latitude + b.latitude) / 2,
      (a.longitude + b.longitude) / 2,
    );
  }

  /// Reverse geocode to get full address string from LatLng
  static Future<String?> getAddressFromLatLng(LatLng latLng) async {
    final placemark = await getPlacemarkFromLatLng(latLng);
    return placemark != null ? formatAddress(placemark) : null;
  }

  /// Check if an address string is valid
  static Future<bool> isValidAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);
      return locations.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Convert bearing to cardinal direction (e.g. N, NE, E)
  static String getCardinalDirection(double bearing) {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW', 'N'];
    return directions[((bearing % 360) / 45).round()];
  }


  static List<LatLng> getNearbyPoints(LatLng center, double radiusInMeters, int count) {
    const earthRadius = 6371000; // in meters
    final points = <LatLng>[];

    for (var i = 0; i < count; i++) {
      final angle = (360 / count) * i;
      final bearingRad = _degToRad(angle);
      final distanceRatio = radiusInMeters / earthRadius;

      final lat1 = _degToRad(center.latitude);
      final lon1 = _degToRad(center.longitude);

      final lat2 = Math.asin(
        Math.sin(lat1) * Math.cos(distanceRatio) +
            Math.cos(lat1) * Math.sin(distanceRatio) * Math.cos(bearingRad),
      );
      final lon2 = lon1 +
          Math.atan2(
            Math.sin(bearingRad) * Math.sin(distanceRatio) * Math.cos(lat1),
            Math.cos(distanceRatio) - Math.sin(lat1) * Math.sin(lat2),
          );

      points.add(LatLng(_radToDeg(lat2), _radToDeg(lon2)));
    }

    return points;
  }



  static Map<String, LatLng> getBoundingBox(LatLng center, double radiusInMeters) {
    const earthRadius = 6378137.0;

    double lat = center.latitude;
    double lng = center.longitude;

    double latDelta = (radiusInMeters / earthRadius) * (180 / 3.1415926535);
    double lngDelta = latDelta / Math.cos(_degToRad(lat));

    return {
      'southwest': LatLng(lat - latDelta, lng - lngDelta),
      'northeast': LatLng(lat + latDelta, lng + lngDelta),
    };
  }


  static String? getComponent(Placemark place, String type) {
    switch (type.toLowerCase()) {
      case 'postal':
        return place.postalCode;
      case 'locality':
        return place.locality;
      case 'admin':
        return place.administrativeArea;
      case 'country':
        return place.country;
      default:
        return null;
    }
  }


  static LatLng roundLatLng(LatLng latLng, {int decimal = 4}) {
    double round(double val) => double.parse(val.toStringAsFixed(decimal));
    return LatLng(round(latLng.latitude), round(latLng.longitude));
  }



  static List<String> getMockCountries() => ['India', 'USA', 'Germany', 'Japan'];
  static List<String> getMockStates(String country) {
    switch (country) {
      case 'India':
        return ['Delhi', 'Maharashtra', 'Karnataka'];
      case 'USA':
        return ['California', 'Texas', 'Florida'];
      default:
        return [];
    }
  }



  static String formatDistance(LatLng a, LatLng b, {bool inKm = true}) {
    final meters = calculateDistance(a, b);
    if (inKm) {
      return '${(meters / 1000).toStringAsFixed(2)} km';
    } else {
      return '${(meters * 0.000621371).toStringAsFixed(2)} miles';
    }
  }







  // -----------------------
  // 🔒 Private helpers
  // -----------------------
  static double _degToRad(double deg) => deg * (3.1415926535 / 180);
  static double _radToDeg(double rad) => rad * (180 / 3.1415926535);
}

