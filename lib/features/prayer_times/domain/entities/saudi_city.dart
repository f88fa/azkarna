import 'dart:math' as math;

/// A Saudi city the user can pick manually; also used to name the place the
/// device reports (nearest city), fully offline.
class SaudiCity {
  const SaudiCity(
    this.id,
    this.name,
    this.region,
    this.latitude,
    this.longitude,
  );

  final String id;
  final String name;
  final String region;
  final double latitude;
  final double longitude;

  bool matches(String query) {
    final q = query.trim();
    if (q.isEmpty) return true;
    return name.contains(q) || region.contains(q);
  }

  /// Great-circle distance in kilometres.
  double distanceKm(double lat, double lng) =>
      haversineKm(latitude, longitude, lat, lng);

  static SaudiCity? byId(String? id) {
    if (id == null) return null;
    for (final c in all) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// The closest city to a coordinate, with its distance in km.
  static (SaudiCity, double) nearest(double lat, double lng) {
    var best = all.first;
    var bestKm = best.distanceKm(lat, lng);
    for (final c in all.skip(1)) {
      final d = c.distanceKm(lat, lng);
      if (d < bestKm) {
        best = c;
        bestKm = d;
      }
    }
    return (best, bestKm);
  }

  static const String country = 'المملكة العربية السعودية';

  static const SaudiCity hail = SaudiCity(
    'hail',
    'حائل',
    'منطقة حائل',
    27.5114,
    41.7208,
  );

  /// Grouped by region, in the order shown in the picker.
  static const List<SaudiCity> all = [
    // الرياض
    SaudiCity('riyadh', 'الرياض', 'منطقة الرياض', 24.7136, 46.6753),
    SaudiCity('diriyah', 'الدرعية', 'منطقة الرياض', 24.7336, 46.5753),
    SaudiCity('kharj', 'الخرج', 'منطقة الرياض', 24.1556, 47.3120),
    SaudiCity('majmaah', 'المجمعة', 'منطقة الرياض', 25.9039, 45.3456),
    SaudiCity('zulfi', 'الزلفي', 'منطقة الرياض', 26.2994, 44.8153),
    SaudiCity('dawadmi', 'الدوادمي', 'منطقة الرياض', 24.5077, 44.3924),
    SaudiCity('shaqra', 'شقراء', 'منطقة الرياض', 25.2483, 45.2528),
    SaudiCity('quwayiyah', 'القويعية', 'منطقة الرياض', 24.0700, 45.2800),
    SaudiCity('afif', 'عفيف', 'منطقة الرياض', 23.9065, 42.9172),
    SaudiCity('aflaj', 'الأفلاج', 'منطقة الرياض', 22.2833, 46.7333),
    SaudiCity('wadi_dawasir', 'وادي الدواسر', 'منطقة الرياض', 20.4667, 44.7833),
    SaudiCity('sulayyil', 'السليل', 'منطقة الرياض', 20.4600, 45.5700),
    // مكة المكرمة
    SaudiCity('makkah', 'مكة المكرمة', 'منطقة مكة المكرمة', 21.3891, 39.8579),
    SaudiCity('jeddah', 'جدة', 'منطقة مكة المكرمة', 21.4858, 39.1925),
    SaudiCity('taif', 'الطائف', 'منطقة مكة المكرمة', 21.2703, 40.4158),
    SaudiCity('jumum', 'الجموم', 'منطقة مكة المكرمة', 21.6170, 39.6980),
    SaudiCity('rabigh', 'رابغ', 'منطقة مكة المكرمة', 22.7986, 39.0349),
    SaudiCity('qunfudhah', 'القنفذة', 'منطقة مكة المكرمة', 19.1264, 41.0789),
    SaudiCity('lith', 'الليث', 'منطقة مكة المكرمة', 20.1500, 40.2667),
    SaudiCity('turabah', 'تربة', 'منطقة مكة المكرمة', 21.2136, 41.6331),
    SaudiCity('khurmah', 'الخرمة', 'منطقة مكة المكرمة', 21.9000, 42.0500),
    SaudiCity('ranyah', 'رنية', 'منطقة مكة المكرمة', 21.2600, 42.8500),
    // المدينة المنورة
    SaudiCity(
      'madinah',
      'المدينة المنورة',
      'منطقة المدينة المنورة',
      24.5247,
      39.5692,
    ),
    SaudiCity('yanbu', 'ينبع', 'منطقة المدينة المنورة', 24.0895, 38.0618),
    SaudiCity('ula', 'العلا', 'منطقة المدينة المنورة', 26.6085, 37.9232),
    SaudiCity('badr', 'بدر', 'منطقة المدينة المنورة', 23.7800, 38.7900),
    SaudiCity('khaybar', 'خيبر', 'منطقة المدينة المنورة', 25.7000, 39.2900),
    // القصيم
    SaudiCity('buraydah', 'بريدة', 'منطقة القصيم', 26.3260, 43.9750),
    SaudiCity('unayzah', 'عنيزة', 'منطقة القصيم', 26.0840, 43.9930),
    SaudiCity('rass', 'الرس', 'منطقة القصيم', 25.8694, 43.4973),
    SaudiCity('mithnab', 'المذنب', 'منطقة القصيم', 25.8601, 44.2223),
    SaudiCity('bukayriyah', 'البكيرية', 'منطقة القصيم', 26.1400, 43.6600),
    // الشرقية
    SaudiCity('dammam', 'الدمام', 'المنطقة الشرقية', 26.4207, 50.0888),
    SaudiCity('khobar', 'الخبر', 'المنطقة الشرقية', 26.2172, 50.1971),
    SaudiCity('dhahran', 'الظهران', 'المنطقة الشرقية', 26.2361, 50.0393),
    SaudiCity('qatif', 'القطيف', 'المنطقة الشرقية', 26.5196, 50.0115),
    SaudiCity('jubail', 'الجبيل', 'المنطقة الشرقية', 27.0174, 49.6225),
    SaudiCity('ahsa', 'الأحساء', 'المنطقة الشرقية', 25.3833, 49.5869),
    SaudiCity(
      'hafr_albatin',
      'حفر الباطن',
      'المنطقة الشرقية',
      28.4328,
      45.9708,
    ),
    SaudiCity('khafji', 'الخفجي', 'المنطقة الشرقية', 28.4392, 48.4914),
    SaudiCity('ras_tanura', 'رأس تنورة', 'المنطقة الشرقية', 26.6436, 50.1594),
    SaudiCity('abqaiq', 'بقيق', 'المنطقة الشرقية', 25.9333, 49.6667),
    SaudiCity('nairyah', 'النعيرية', 'المنطقة الشرقية', 27.4700, 48.4880),
    // حائل
    hail,
    // تبوك
    SaudiCity('tabuk', 'تبوك', 'منطقة تبوك', 28.3835, 36.5662),
    SaudiCity('wajh', 'الوجه', 'منطقة تبوك', 26.2333, 36.4667),
    SaudiCity('duba', 'ضباء', 'منطقة تبوك', 27.3500, 35.6900),
    SaudiCity('umluj', 'أملج', 'منطقة تبوك', 25.0213, 37.2685),
    SaudiCity('tayma', 'تيماء', 'منطقة تبوك', 27.6333, 38.5500),
    // الجوف
    SaudiCity('sakaka', 'سكاكا', 'منطقة الجوف', 29.9697, 40.2064),
    SaudiCity('dumat_jandal', 'دومة الجندل', 'منطقة الجوف', 29.8117, 39.8681),
    SaudiCity('qurayyat', 'القريات', 'منطقة الجوف', 31.3317, 37.3428),
    // الحدود الشمالية
    SaudiCity('arar', 'عرعر', 'منطقة الحدود الشمالية', 30.9753, 41.0381),
    SaudiCity('rafha', 'رفحاء', 'منطقة الحدود الشمالية', 29.6264, 43.4931),
    SaudiCity('turaif', 'طريف', 'منطقة الحدود الشمالية', 31.6725, 38.6637),
    // عسير
    SaudiCity('abha', 'أبها', 'منطقة عسير', 18.2164, 42.5053),
    SaudiCity('khamis_mushait', 'خميس مشيط', 'منطقة عسير', 18.3000, 42.7333),
    SaudiCity('bisha', 'بيشة', 'منطقة عسير', 19.9917, 42.5992),
    SaudiCity('namas', 'النماص', 'منطقة عسير', 19.1167, 42.1333),
    SaudiCity('muhayil', 'محايل عسير', 'منطقة عسير', 18.5333, 42.0500),
    SaudiCity('ahad_rufaidah', 'أحد رفيدة', 'منطقة عسير', 18.2100, 42.8300),
    SaudiCity('sarat_abidah', 'سراة عبيدة', 'منطقة عسير', 18.0900, 43.1200),
    SaudiCity('dhahran_janub', 'ظهران الجنوب', 'منطقة عسير', 17.6700, 43.5000),
    // الباحة
    SaudiCity('baha', 'الباحة', 'منطقة الباحة', 20.0129, 41.4677),
    SaudiCity('baljurashi', 'بلجرشي', 'منطقة الباحة', 19.8575, 41.5600),
    // جازان
    SaudiCity('jazan', 'جازان', 'منطقة جازان', 16.8892, 42.5511),
    SaudiCity('sabya', 'صبيا', 'منطقة جازان', 17.1500, 42.6250),
    SaudiCity('abu_arish', 'أبو عريش', 'منطقة جازان', 16.9689, 42.8325),
    SaudiCity('samtah', 'صامطة', 'منطقة جازان', 16.5964, 42.9444),
    // نجران
    SaudiCity('najran', 'نجران', 'منطقة نجران', 17.5656, 44.2289),
    SaudiCity('sharurah', 'شرورة', 'منطقة نجران', 17.4667, 47.1167),
  ];
}

double haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLng = rad(lng2 - lng1);
  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(rad(lat1)) *
          math.cos(rad(lat2)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return 2 * r * math.asin(math.sqrt(a));
}
