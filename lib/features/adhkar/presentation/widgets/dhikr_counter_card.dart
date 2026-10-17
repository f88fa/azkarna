import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/arabic_format.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/entities/adhkar_category.dart';

class DhikrCounterCard extends StatelessWidget {
  const DhikrCounterCard({
    super.key,
    required this.dhikr,
    required this.current,
    required this.onTap,
    this.menu,
  });

  final Dhikr dhikr;
  final int current;
  final VoidCallback onTap;

  /// Optional action menu shown at the card's start corner.
  final Widget? menu;

  bool get _done => current >= dhikr.count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondary = theme.colorScheme.onSurface.withValues(alpha: 0.55);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: _done ? 0.6 : 1,
      child: GlassCard(
        radius: 24,
        onTap: _done
            ? null
            : () {
                HapticFeedback.lightImpact();
                onTap();
              },
        child: Stack(
          children: [
            SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  Text(
                    dhikr.text,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(fontSize: 24, height: 1.9),
                  ),
                  if (dhikr.reference.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      'رواه ${arabicReference(dhikr.reference)}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: secondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _CounterBadge(
                    current: current,
                    target: dhikr.count,
                    done: _done,
                  ),
                ],
              ),
            ),
            if (menu != null)
              PositionedDirectional(top: -8, start: -8, child: menu!),
          ],
        ),
      ),
    );
  }
}

class _CounterBadge extends StatelessWidget {
  const _CounterBadge({
    required this.current,
    required this.target,
    required this.done,
  });

  final int current;
  final int target;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return SizedBox(
      width: 76,
      height: 76,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: (current / target).clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              builder: (context, value, _) => CircularProgressIndicator(
                value: value,
                strokeWidth: 5,
                strokeCap: StrokeCap.round,
                backgroundColor: primary.withValues(alpha: 0.12),
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: done
                ? Icon(
                    Icons.check_rounded,
                    key: const ValueKey('done'),
                    size: 32,
                    color: primary,
                  )
                : Text(
                    '${arNum(current)}/${arNum(target)}',
                    key: ValueKey(current),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Arabic names for the hadith sources used in the adhkar data.
String arabicReference(String reference) {
  const names = {
    'Al-Bukhari': 'البخاري',
    'Muslim': 'مسلم',
    'Abu Dawud': 'أبو داود',
    'At-Tirmidhi': 'الترمذي',
    'An-Nasa\'i': 'النسائي',
    'Ibn Majah': 'ابن ماجه',
    'Ahmad': 'أحمد',
    'Al-Hakim': 'الحاكم',
  };
  return reference
      .split(',')
      .map((part) => names[part.trim()] ?? part.trim())
      .join('، ');
}
