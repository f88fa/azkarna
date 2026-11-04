import 'package:azkarna/features/prayer_times/domain/entities/saudi_city.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('nearest city for a point in Riyadh is Riyadh', () {
    final (city, km) = SaudiCity.nearest(24.69, 46.72);
    expect(city.id, 'riyadh');
    expect(km, lessThan(10));
  });

  test('nearest city for a point in Hail is Hail', () {
    final (city, _) = SaudiCity.nearest(27.52, 41.69);
    expect(city.id, 'hail');
  });

  test('city ids are unique', () {
    final ids = SaudiCity.all.map((c) => c.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('search matches names and regions', () {
    expect(SaudiCity.byId('jeddah')!.matches('جد'), isTrue);
    expect(SaudiCity.byId('dammam')!.matches('الشرقية'), isTrue);
  });
}
