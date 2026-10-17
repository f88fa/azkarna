import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../quran/presentation/providers/quran_providers.dart';
import '../../domain/entities/khatmah_progress.dart';
import '../providers/khatmah_providers.dart';

class KhatmahCard extends ConsumerWidget {
  const KhatmahCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final progress = ref.watch(khatmahProvider);
    final surahs = ref.watch(surahsProvider).asData?.value;

    return progress.when(
      loading: () => const SizedBox(height: 150),
      error: (_, _) => const SizedBox.shrink(),
      data: (data) {
        final bookmark = data.bookmark;
        String? surahName;
        if (bookmark != null) {
          surahName = 'Surah ${bookmark.surahNumber}';
          for (final s in surahs ?? const []) {
            if (s.number == bookmark.surahNumber) surahName = s.englishName;
          }
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.bookmark_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Khatmah',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _editTarget(context, ref, data),
                    child: Text('Goal: ${data.dailyTarget}/day'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                bookmark == null
                    ? 'Start reading to save your place'
                    : '$surahName · Ayah ${bookmark.ayahNumber}',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: data.todayFraction),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => LinearProgressIndicator(
                    value: value,
                    minHeight: 8,
                    backgroundColor: theme.colorScheme.primary.withValues(
                      alpha: 0.12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Today: ${data.todayRead} / ${data.dailyTarget} ayahs',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => context.push(
                    bookmark == null
                        ? AppRoutes.surah(1)
                        : AppRoutes.surah(
                            bookmark.surahNumber,
                            ayah: bookmark.ayahNumber,
                          ),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.menu_book_rounded),
                  label: Text(bookmark == null ? 'Start reading' : 'Resume'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editTarget(
    BuildContext context,
    WidgetRef ref,
    KhatmahProgress progress,
  ) async {
    final result = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (_) => _TargetSheet(initial: progress.dailyTarget),
    );
    if (result != null) {
      await ref.read(khatmahProvider.notifier).setDailyTarget(result);
    }
  }
}

class _TargetSheet extends StatefulWidget {
  const _TargetSheet({required this.initial});

  final int initial;

  @override
  State<_TargetSheet> createState() => _TargetSheetState();
}

class _TargetSheetState extends State<_TargetSheet> {
  late int _value = widget.initial;

  void _change(int delta) =>
      setState(() => _value = (_value + delta).clamp(1, 1000));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Daily reading goal',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filledTonal(
                  onPressed: () => _change(-5),
                  icon: const Icon(Icons.remove_rounded),
                ),
                SizedBox(
                  width: 120,
                  child: Column(
                    children: [
                      Text(
                        '$_value',
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Text('ayahs / day'),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () => _change(5),
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(_value),
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
