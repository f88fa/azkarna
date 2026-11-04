import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

enum LocationAccess { granted, denied, deniedForever, serviceOff }

/// Thin wrapper over `geolocator`. City-level accuracy is all prayer times
/// need, so it asks for the coarse/low-power fix.
class DeviceLocationService {
  const DeviceLocationService();

  Future<LocationAccess> access({required bool request}) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return LocationAccess.serviceOff;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && request) {
        permission = await Geolocator.requestPermission();
      }
      return switch (permission) {
        LocationPermission.always ||
        LocationPermission.whileInUse => LocationAccess.granted,
        LocationPermission.deniedForever => LocationAccess.deniedForever,
        _ => LocationAccess.denied,
      };
    } catch (_) {
      return LocationAccess.denied;
    }
  }

  /// Current position, falling back to the last known fix. Null on failure.
  Future<({double lat, double lng})?> position() async {
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return (lat: p.latitude, lng: p.longitude);
    } catch (_) {
      if (kIsWeb) return null;
      try {
        final p = await Geolocator.getLastKnownPosition();
        return p == null ? null : (lat: p.latitude, lng: p.longitude);
      } catch (_) {
        return null;
      }
    }
  }

  Future<void> openSettings() async {
    try {
      await Geolocator.openAppSettings();
    } catch (_) {}
  }

  Future<void> openLocationSettings() async {
    try {
      await Geolocator.openLocationSettings();
    } catch (_) {}
  }
}
