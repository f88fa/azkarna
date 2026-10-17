import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../../core/error/failures.dart';
import '../../domain/entities/prayer_location.dart';
import '../models/prayer_times_model.dart';

abstract interface class PrayerTimesRemoteDataSource {
  Future<PrayerTimesModel> fetchTimingsByCity(PrayerLocation location);

  /// All days of the given Gregorian [month].
  Future<List<PrayerTimesModel>> fetchCalendarByCity(
    PrayerLocation location, {
    required int year,
    required int month,
  });
}

class AladhanPrayerTimesRemoteDataSource
    implements PrayerTimesRemoteDataSource {
  const AladhanPrayerTimesRemoteDataSource(this._client);

  final http.Client _client;

  static const String _host = 'api.aladhan.com';
  // 4 = Umm Al-Qura University, Makkah.
  static const String _method = '4';
  static const Duration _timeout = Duration(seconds: 15);

  Map<String, String> _query(PrayerLocation location) => {
    'city': location.city,
    'country': location.country,
    'method': _method,
  };

  String _label(PrayerLocation location) =>
      '${location.city}, ${location.country}';

  @override
  Future<PrayerTimesModel> fetchTimingsByCity(PrayerLocation location) {
    final uri = Uri.https(_host, '/v1/timingsByCity', _query(location));
    return _request(uri, (decoded) {
      return PrayerTimesModel.fromJson(
        decoded,
        location: _label(location),
        fallbackTimeZone: location.timeZone,
      );
    });
  }

  @override
  Future<List<PrayerTimesModel>> fetchCalendarByCity(
    PrayerLocation location, {
    required int year,
    required int month,
  }) {
    final uri = Uri.https(
      _host,
      '/v1/calendarByCity/$year/$month',
      _query(location),
    );
    return _request(uri, (decoded) {
      final data = decoded['data'];
      if (data is! List) throw const FormatException('Missing "data" list');
      return data
          .map((day) {
            if (day is! Map<String, dynamic>) {
              throw const FormatException('Invalid calendar entry');
            }
            return PrayerTimesModel.fromDayJson(
              day,
              location: _label(location),
              fallbackTimeZone: location.timeZone,
            );
          })
          .toList(growable: false);
    });
  }

  Future<T> _request<T>(
    Uri uri,
    T Function(Map<String, dynamic> decoded) parse,
  ) async {
    try {
      final response = await _client.get(uri).timeout(_timeout);
      if (response.statusCode != 200) {
        throw ServerFailure('Server responded with ${response.statusCode}');
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Unexpected response');
      }
      return parse(decoded);
    } on Failure {
      rethrow;
    } on SocketException {
      throw const NetworkFailure();
    } on http.ClientException {
      throw const NetworkFailure();
    } on TimeoutException {
      throw const NetworkFailure('Request timed out');
    } on FormatException {
      throw const ServerFailure('Invalid data received from server');
    }
  }
}
