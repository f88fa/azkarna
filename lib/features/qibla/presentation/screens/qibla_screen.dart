import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/arabic_format.dart';
import '../../../../core/widgets/popup_scaffold.dart';
import '../../../prayer_times/presentation/providers/location_providers.dart';
import '../../../settings/presentation/widgets/settings_group.dart';
import '../../domain/qibla.dart';

/// Qibla compass: the dial turns with the phone; the Kaaba marker sits at the
/// Qibla bearing, and the screen turns green when the top of the phone faces
/// it.
class QiblaScreen extends ConsumerStatefulWidget {
  const QiblaScreen({super.key});

  @override
  ConsumerState<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends ConsumerState<QiblaScreen> {
  /// Within this many degrees the phone counts as facing the Qibla.
  static const double _tolerance = 5;

  StreamSubscription<CompassEvent>? _sub;
  Timer? _noSensorTimer;

  /// Unwrapped heading (keeps growing past 360) so the dial never spins the
  /// long way round when crossing north.
  double? _heading;
  double? _accuracy;
  bool _noSensor = false;
  bool _wasAligned = false;

  @override
  void initState() {
    super.initState();
    _sub = FlutterCompass.events?.listen(
      _onEvent,
      onError: (_) {
        if (mounted) setState(() => _noSensor = true);
      },
    );
    if (_sub == null) _noSensor = true;
    _noSensorTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _heading == null) setState(() => _noSensor = true);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _noSensorTimer?.cancel();
    super.dispose();
  }

  void _onEvent(CompassEvent event) {
    final h = event.heading;
    if (h == null || !mounted) return;
    final raw = (h + 360) % 360;
    setState(() {
      final prev = _heading;
      _heading = prev == null ? raw : prev + angleDelta(prev % 360, raw);
      _accuracy = event.accuracy;
      _noSensor = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(locationProvider);
    final location = state.location;
    final qibla = qiblaBearing(location.latitude, location.longitude);
    final distance = distanceToKaabaKm(location.latitude, location.longitude);
    final theme = Theme.of(context);
    final heading = _heading;

    final delta = heading == null ? null : angleDelta(heading % 360, qibla);
    final aligned = delta != null && delta.abs() <= _tolerance;
    if (aligned && !_wasAligned) HapticFeedback.mediumImpact();
    _wasAligned = aligned;

    final accent = aligned
        ? const Color(0xFF16A34A)
        : theme.colorScheme.primary;

    final String status;
    if (heading == null) {
      status = _noSensor
          ? 'لا يتوفر حساس البوصلة في هذا الجهاز'
          : 'جارٍ تشغيل البوصلة…';
    } else if (aligned) {
      status = 'أنت متجه إلى القبلة';
    } else {
      final turn = delta! > 0 ? 'يمينًا' : 'يسارًا';
      status = 'استدر ${arNum(delta.abs().round())}° $turn';
    }

    return PopupScaffold(
      title: 'اتجاه القبلة',
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.only(top: 4, bottom: 24),
        child: Column(
          children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: theme.textTheme.titleLarge!.copyWith(
                fontWeight: FontWeight.w800,
                color: accent,
              ),
              child: Text(status, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 6),
            Text(
              'القبلة ${arNum(qibla.round())}° من الشمال · نحو ${bearingName(qibla)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 22),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: AspectRatio(
                aspectRatio: 1,
                child: _Compass(
                  // Without a sensor show a static dial, north up.
                  headingDegrees: heading ?? 0,
                  qiblaDegrees: qibla,
                  accent: accent,
                  aligned: aligned,
                ),
              ),
            ),
            const SizedBox(height: 22),
            SettingsSection(
              title: 'الموقع',
              footer: _noSensor && heading == null
                  ? 'وجّه أعلى الجوال نحو الشمال، ثم اتجه نحو علامة الكعبة.'
                  : (_accuracy != null && _accuracy! > 30)
                  ? 'دقة البوصلة ضعيفة: حرّك الجوال في الهواء على شكل رقم ٨، '
                        'وابتعد عن المعادن والأجهزة المغناطيسية.'
                  : 'ضع الجوال مسطّحًا وبعيدًا عن المعادن للحصول على اتجاه دقيق.',
              children: [
                SettingsValueTile(
                  icon: Icons.location_on_rounded,
                  color: AppColors.red,
                  title: state.isAuto ? 'موقعك الحالي' : 'المدينة',
                  value: location.city,
                  onTap: () => context.push(AppRoutes.settingsLocation),
                ),
                SettingsValueTile(
                  icon: Icons.straighten_rounded,
                  color: AppColors.amber,
                  title: 'المسافة إلى مكة المكرمة',
                  value: '${arNum(distance.round())} كم',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Compass extends StatelessWidget {
  const _Compass({
    required this.headingDegrees,
    required this.qiblaDegrees,
    required this.accent,
    required this.aligned,
  });

  final double headingDegrees;
  final double qiblaDegrees;
  final Color accent;
  final bool aligned;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final face = dark ? AppColors.darkCard : Colors.white;
    final ink = theme.colorScheme.onSurface;

    return LayoutBuilder(
      builder: (context, box) {
        final size = box.maxWidth;
        final radius = size / 2;
        final qiblaRad = qiblaDegrees * math.pi / 180;
        // Kaaba marker inside the rim, at the Qibla bearing on the dial.
        final markerR = radius * 0.50;
        final marker = Offset(
          radius + markerR * math.sin(qiblaRad),
          radius - markerR * math.cos(qiblaRad),
        );

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Rotating dial (rotates opposite to the heading).
            AnimatedRotation(
              turns: -headingDegrees / 360,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              child: SizedBox(
                width: size,
                height: size,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: face,
                          border: Border.all(
                            color: accent.withValues(alpha: 0.55),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.18),
                              blurRadius: 30,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: CustomPaint(
                          painter: _DialPainter(
                            ink: ink,
                            north: AppColors.red,
                            qiblaDegrees: qiblaDegrees,
                            accent: accent,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: marker.dx - 22,
                      top: marker.dy - 22,
                      // Keep the Kaaba upright while the dial turns.
                      child: AnimatedRotation(
                        turns: headingDegrees / 360,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        child: const _KaabaIcon(size: 44),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Fixed pointer: the top of the phone.
            Positioned(
              left: radius - 14,
              top: -18,
              child: Icon(Icons.navigation_rounded, size: 28, color: accent),
            ),
            // Centre hub.
            Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: aligned ? 22 : 14,
                height: aligned ? 22 : 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent,
                  border: Border.all(color: face, width: 3),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DialPainter extends CustomPainter {
  _DialPainter({
    required this.ink,
    required this.north,
    required this.qiblaDegrees,
    required this.accent,
  });

  final Color ink;
  final Color north;
  final double qiblaDegrees;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;

    // Ticks every 5°, longer every 30°.
    final tick = Paint()..strokeCap = StrokeCap.round;
    for (var d = 0; d < 360; d += 5) {
      final major = d % 30 == 0;
      final a = d * math.pi / 180;
      final outer = r - 10;
      final inner = outer - (major ? 14 : 7);
      tick
        ..color = ink.withValues(alpha: major ? 0.55 : 0.22)
        ..strokeWidth = major ? 2.4 : 1.4;
      canvas.drawLine(
        c + Offset(math.sin(a) * inner, -math.cos(a) * inner),
        c + Offset(math.sin(a) * outer, -math.cos(a) * outer),
        tick,
      );
    }

    // Line from the centre towards the Qibla.
    final q = qiblaDegrees * math.pi / 180;
    final line = Paint()
      ..color = accent.withValues(alpha: 0.55)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      c,
      c + Offset(math.sin(q) * r * 0.38, -math.cos(q) * r * 0.38),
      line,
    );

    // Cardinal letters (Arabic): ش ق ج غ.
    const labels = {0: 'ش', 90: 'ق', 180: 'ج', 270: 'غ'};
    for (final e in labels.entries) {
      final a = e.key * math.pi / 180;
      final pos = c + Offset(math.sin(a), -math.cos(a)) * (r - 42);
      final tp = TextPainter(
        text: TextSpan(
          text: e.value,
          style: TextStyle(
            color: e.key == 0 ? north : ink.withValues(alpha: 0.75),
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.rtl,
      )..layout();
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(a);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.ink != ink ||
      old.qiblaDegrees != qiblaDegrees ||
      old.accent != accent;
}

/// A simple drawn Kaaba: black cube with a gold band.
class _KaabaIcon extends StatelessWidget {
  const _KaabaIcon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.16),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF151515),
          borderRadius: BorderRadius.circular(3),
        ),
        alignment: const Alignment(0, -0.45),
        child: Container(height: size * 0.09, color: const Color(0xFFD4A537)),
      ),
    );
  }
}
