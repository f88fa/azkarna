import 'package:adhan/adhan.dart' as adhan;

import '../../prayer_times/domain/entities/saudi_city.dart';

/// Holy Kaaba coordinates.
const double kaabaLatitude = 21.4225241;
const double kaabaLongitude = 39.8261818;

/// Qibla bearing in degrees clockwise from true north (0 – 360).
double qiblaBearing(double latitude, double longitude) =>
    adhan.Qibla(adhan.Coordinates(latitude, longitude)).direction;

/// Great-circle distance to the Kaaba in kilometres.
double distanceToKaabaKm(double latitude, double longitude) =>
    haversineKm(latitude, longitude, kaabaLatitude, kaabaLongitude);

/// Signed smallest angle from [from] to [to], in (-180, 180].
double angleDelta(double from, double to) {
  var d = (to - from) % 360;
  if (d > 180) d -= 360;
  return d;
}

/// Arabic name of the compass sector for a bearing.
String bearingName(double bearing) {
  const names = [
    'الشمال',
    'الشمال الشرقي',
    'الشرق',
    'الجنوب الشرقي',
    'الجنوب',
    'الجنوب الغربي',
    'الغرب',
    'الشمال الغربي',
  ];
  return names[((bearing % 360) / 45).round() % 8];
}
