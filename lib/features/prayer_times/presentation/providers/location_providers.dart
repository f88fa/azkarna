import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/storage/shared_preferences_provider.dart';
import '../../data/services/device_location_service.dart';
import '../../domain/entities/prayer_location.dart';
import '../../domain/entities/saudi_city.dart';

enum LocationMode { auto, manual }

class LocationState {
  const LocationState({
    required this.mode,
    required this.location,
    this.cityId,
    this.firstRun = false,
  });

  final LocationMode mode;
  final PrayerLocation location;

  /// The picked city (manual) or the nearest known city (auto).
  final String? cityId;

  /// No choice saved yet: try GPS once, fall back to manual on refusal.
  final bool firstRun;

  bool get isAuto => mode == LocationMode.auto;
}

/// Result of an attempt to read the device location.
sealed class LocationOutcome {
  const LocationOutcome();
}

class LocationUpdated extends LocationOutcome {
  const LocationUpdated({required this.location, required this.cityChanged});
  final PrayerLocation location;
  final bool cityChanged;
}

class LocationFailed extends LocationOutcome {
  const LocationFailed(this.access);

  /// Null when permission was fine but no fix could be obtained.
  final LocationAccess? access;

  String get message => switch (access) {
    LocationAccess.serviceOff =>
      'خدمة الموقع متوقفة في جهازك. فعّلها ثم حاول مرة أخرى.',
    LocationAccess.deniedForever || LocationAccess.denied =>
      'لم يُسمح للتطبيق بالوصول إلى الموقع. اسمح به من إعدادات الجهاز أو اختر مدينتك يدويًا.',
    _ => 'تعذّر تحديد موقعك الآن. حاول مرة أخرى بعد قليل.',
  };
}

final deviceLocationServiceProvider = Provider<DeviceLocationService>(
  (ref) => const DeviceLocationService(),
);

final locationProvider = NotifierProvider<LocationNotifier, LocationState>(
  LocationNotifier.new,
);

class LocationNotifier extends Notifier<LocationState> {
  static const _kMode = 'location_mode';
  static const _kCity = 'location_city_id';
  static const _kLat = 'location_auto_lat';
  static const _kLng = 'location_auto_lng';
  static const _kTz = 'location_auto_tz';
  static const _kOffset = 'location_auto_offset_min';
  static const _kDeclined = 'location_declined_city_id';

  /// Movement below this is ignored (same city, GPS jitter).
  static const double _minMoveKm = 3;

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);
  DeviceLocationService get _device => ref.read(deviceLocationServiceProvider);

  @override
  LocationState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final mode = prefs.getString(_kMode);
    final city = SaudiCity.byId(prefs.getString(_kCity));

    if (mode == LocationMode.auto.name) {
      final lat = prefs.getDouble(_kLat);
      final lng = prefs.getDouble(_kLng);
      if (lat != null && lng != null) {
        final (location, nearest) = _fromCoordinates(
          lat,
          lng,
          prefs.getString(_kTz),
          Duration(minutes: prefs.getInt(_kOffset) ?? 180),
        );
        return LocationState(
          mode: LocationMode.auto,
          location: location,
          cityId: nearest?.id,
        );
      }
      final fallback = city ?? SaudiCity.hail;
      return LocationState(
        mode: LocationMode.auto,
        location: _fromCity(fallback),
        cityId: fallback.id,
      );
    }

    final picked = city ?? SaudiCity.hail;
    return LocationState(
      mode: LocationMode.manual,
      location: _fromCity(picked),
      cityId: picked.id,
      firstRun: mode == null,
    );
  }

  /// Manual choice of a Saudi city.
  Future<void> setManual(SaudiCity city) async {
    await _prefs.setString(_kMode, LocationMode.manual.name);
    await _prefs.setString(_kCity, city.id);
    state = LocationState(
      mode: LocationMode.manual,
      location: _fromCity(city),
      cityId: city.id,
    );
  }

  /// Switches to automatic mode and reads the device location now.
  Future<LocationOutcome> enableAuto() async {
    final outcome = await _readDevice(request: true, force: true);
    return outcome;
  }

  /// Called on launch and when the app returns to the foreground.
  ///
  /// * First run: asks for permission once; refusal keeps the manual city.
  /// * Auto mode: silently follows the device (no prompt).
  /// * Manual mode: returns nothing (see [detectMovedCity]).
  Future<LocationOutcome?> refreshIfAuto() async {
    final current = state;
    if (current.firstRun) {
      final outcome = await _readDevice(request: true, force: true);
      if (outcome is LocationFailed) {
        await _prefs.setString(_kMode, LocationMode.manual.name);
        state = LocationState(
          mode: LocationMode.manual,
          location: current.location,
          cityId: current.cityId,
        );
      }
      return outcome;
    }
    if (!current.isAuto) return null;
    return _readDevice(request: false, force: false);
  }

  /// Manual mode only: if permission is already granted and the device is in
  /// another known city (not one the user already declined), returns it so
  /// the app can ask "هل انتقلت إلى …؟".
  Future<SaudiCity?> detectMovedCity() async {
    if (state.isAuto) return null;
    if (await _device.access(request: false) != LocationAccess.granted) {
      return null;
    }
    final pos = await _device.position();
    if (pos == null) return null;
    final (city, km) = SaudiCity.nearest(pos.lat, pos.lng);
    if (km > 40 || city.id == state.cityId) {
      // Back in the chosen city: forget an earlier "no" so a later move asks.
      if (city.id == state.cityId) await _prefs.remove(_kDeclined);
      return null;
    }
    if (_prefs.getString(_kDeclined) == city.id) return null;
    return city;
  }

  /// The user answered "no" to the move prompt for [city].
  Future<void> declineMove(SaudiCity city) =>
      _prefs.setString(_kDeclined, city.id);

  Future<LocationOutcome> _readDevice({
    required bool request,
    required bool force,
  }) async {
    final access = await _device.access(request: request);
    if (access != LocationAccess.granted) return LocationFailed(access);
    final pos = await _device.position();
    if (pos == null) return const LocationFailed(null);

    final previous = state;
    final moved =
        haversineKm(
          previous.location.latitude,
          previous.location.longitude,
          pos.lat,
          pos.lng,
        ) >=
        _minMoveKm;

    if (!force && previous.isAuto && !moved) {
      return LocationUpdated(location: previous.location, cityChanged: false);
    }

    final (tzName, offset) = await _deviceTimeZone();
    final (location, nearest) = _fromCoordinates(
      pos.lat,
      pos.lng,
      tzName,
      offset,
    );

    await _prefs.setString(_kMode, LocationMode.auto.name);
    await _prefs.setDouble(_kLat, pos.lat);
    await _prefs.setDouble(_kLng, pos.lng);
    await _prefs.setString(_kTz, location.timeZone);
    await _prefs.setInt(_kOffset, location.utcOffset.inMinutes);
    await _prefs.remove(_kDeclined);

    state = LocationState(
      mode: LocationMode.auto,
      location: location,
      cityId: nearest?.id,
    );
    return LocationUpdated(
      location: location,
      cityChanged: previous.location.city != location.city,
    );
  }

  Future<(String?, Duration)> _deviceTimeZone() async {
    final offset = DateTime.now().timeZoneOffset;
    if (kIsWeb) return (null, offset);
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      return (info.identifier, offset);
    } catch (_) {
      return (null, offset);
    }
  }

  static PrayerLocation _fromCity(SaudiCity city) => PrayerLocation(
    city: city.name,
    country: SaudiCity.country,
    latitude: city.latitude,
    longitude: city.longitude,
    timeZone: 'Asia/Riyadh',
    utcOffset: const Duration(hours: 3),
  );

  /// Builds a location from raw coordinates; inside Saudi Arabia it is named
  /// after the nearest city and pinned to Riyadh time.
  static (PrayerLocation, SaudiCity?) _fromCoordinates(
    double lat,
    double lng,
    String? tzName,
    Duration offset,
  ) {
    final (city, km) = SaudiCity.nearest(lat, lng);
    final inSaudi = km <= 60;
    final name = km <= 25
        ? city.name
        : inSaudi
        ? 'قرب ${city.name}'
        : 'موقعك الحالي';
    return (
      PrayerLocation(
        city: name,
        country: inSaudi ? SaudiCity.country : '',
        latitude: lat,
        longitude: lng,
        timeZone: inSaudi ? 'Asia/Riyadh' : (tzName ?? 'UTC'),
        utcOffset: inSaudi ? const Duration(hours: 3) : offset,
      ),
      inSaudi ? city : null,
    );
  }
}
