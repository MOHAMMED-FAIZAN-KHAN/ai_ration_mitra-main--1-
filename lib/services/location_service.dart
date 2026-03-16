import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';

class LocationService {
  static Future<bool> requestLocationPermission() async {
    final permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      final result = await Geolocator.requestPermission();
      return result == LocationPermission.whileInUse ||
          result == LocationPermission.always;
    } else if (permission == LocationPermission.deniedForever) {
      // Open app settings
      await Geolocator.openLocationSettings();
      return false;
    }
    return true;
  }

  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  static Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) return null;

      final isEnabled = await isLocationServiceEnabled();
      if (!isEnabled) {
        await Geolocator.openLocationSettings();
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return position;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting location: $e');
      }
      return null;
    }
  }

  static Future<String?> getAddressFromCoordinates(
      double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return '${place.street}, ${place.locality}, ${place.postalCode}';
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting address: $e');
      }
      return null;
    }
  }

  static Future<List<Location>> getCoordinatesFromAddress(
      String address) async {
    try {
      return await locationFromAddress(address);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting coordinates: $e');
      }
      return [];
    }
  }

  static double calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) /
        1000; // Returns distance in km
  }
}
