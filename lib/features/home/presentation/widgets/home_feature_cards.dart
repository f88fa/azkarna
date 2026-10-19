import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/arabic_format.dart';
import '../../../quran/presentation/providers/kahf_providers.dart';
import '../../../tasbeeh/presentation/providers/tasbeeh_providers.dart';

/// Two feature cards under the adhkar: the tasbeeh counter and Surah Al-Kahf.
class HomeFeatureCards extends ConsumerWidget {
  const HomeFeatureCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasbeeh = ref.watch(tasbeehProvider);
    final progress = ref.watch(kahfProgressProvider);
    final isFriday = DateTime.now().weekday == DateTime.friday;

    final kahfSubtitle = progress > 0.005
        ? 'أكملت ${arNum((progress * 100).round())}٪ · تابع القراءة'
        : (isFriday ? 'اليوم الجمعة · ابدأ القراءة' : 'ابدأ القراءة');

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _FeatureCard(
              icon: Icons.touch_app_rounded,
              title: 'المسبحة',
              subtitle: tasbeeh.count > 0
                  ? 'وصلت إلى ${arNum(tasbeeh.count)}'
                        '${tasbeeh.target > 0 ? ' من ${arNum(tasbeeh.target)}' : ''}'
                  : 'عدّاد التسبيح',
              progress: tasbeeh.progress,
              colors: const [Color(0xFF0E9F6E), Color(0xFF0B7A55)],
              onTap: () => context.push(AppRoutes.tasbeeh),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _FeatureCard(
              icon: Icons.menu_book_rounded,
              title: 'سورة الكهف',
              subtitle: kahfSubtitle,
              progress: progress,
              badge: isFriday ? 'الجمعة' : null,
              colors: const [Color(0xFFB8860B), Color(0xFF8A6508)],
              onTap: () => context.push(AppRoutes.kahf),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.onTap,
    required this.progress,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> colors;
  final VoidCallback onTap;
  final String? badge;

  /// 0 – 1: a line under the card shows how far along the user is.
  final double progress;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(26);
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: RepaintBoundary(
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: colors,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.last.withValues(alpha: 0.32),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: radius,
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(icon, color: Colors.white, size: 24),
                        ),
                        const Spacer(),
                        if (badge != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              badge!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Progress line: starts at the right (RTL) and grows left.
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        minHeight: 5,
                        backgroundColor: Colors.white.withValues(alpha: 0.25),
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
