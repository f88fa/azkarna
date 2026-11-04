import 'package:azkarna/features/qibla/domain/qibla.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Qibla from Riyadh points west-south-west (~244°)', () {
    final b = qiblaBearing(24.7136, 46.6753);
    expect(b, inInclusiveRange(240, 248));
  });

  test('distance from Riyadh to Makkah is about 790 km', () {
    expect(distanceToKaabaKm(24.7136, 46.6753), inInclusiveRange(760, 820));
  });

  test('angleDelta takes the short way round north', () {
    expect(angleDelta(350, 10), 20);
    expect(angleDelta(10, 350), -20);
  });
}
