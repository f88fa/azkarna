import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Web-only preview helper: centers the app in an iPhone 15 Pro Max sized
/// viewport (430 x 932) with rounded corners, a bezel and a soft shadow.
///
/// On narrow windows (a real phone browser) the app is shown full screen.
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({super.key, required this.child});

  final Widget child;

  static const double width = 430;
  static const double height = 932;
  static const double _topInset = 54; // status bar / dynamic island
  static const double _bottomInset = 34; // home indicator

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    if (media.size.width < width + 40) return child;

    return ColoredBox(
      color: const Color(0xFFE9EDF2),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Shrink the device to fit short windows, keeping the layout size.
          final scale = math.min(1.0, (constraints.maxHeight - 48) / height);
          return Center(
            child: SizedBox(
              width: width * scale,
              height: height * scale,
              child: FittedBox(
                child: SizedBox(
                  width: width,
                  height: height,
                  child: _Device(child: child),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Device extends StatelessWidget {
  const _Device({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    const radius = 56.0;
    final media = MediaQuery.of(context);
    const size = Size(PhoneFrame.width, PhoneFrame.height);
    const padding = EdgeInsets.only(
      top: PhoneFrame._topInset,
      bottom: PhoneFrame._bottomInset,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 60,
            spreadRadius: 2,
            offset: const Offset(0, 30),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            MediaQuery(
              data: media.copyWith(
                size: size,
                padding: padding,
                viewPadding: padding,
              ),
              child: child,
            ),
            // Bezel.
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(color: const Color(0xFF111114), width: 10),
                ),
              ),
            ),
            // Dynamic island.
            const Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.only(top: 14),
                child: IgnorePointer(
                  child: SizedBox(
                    width: 122,
                    height: 34,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color(0xFF111114),
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
