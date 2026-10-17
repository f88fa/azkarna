import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/arabic_format.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/gradient_progress_bar.dart';
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
          surahName = 'سورة ${arNum(bookmark.surahNumber)}';
          for (final s in surahs ?? const []) {
            if (s.number == bookmark.surahNumber) surahName = 'سورة ${s.name}';
          }
        }
        final percent = (data.todayFraction * 100).round();
        final secondary = theme.colorScheme.onSurface.withValues(alpha: 0.6);

        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.bookmark_rounded,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'الختمة',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _editTarget(context, ref, data),
                    child: Text('الهدف: ${arNum(data.dailyTarget)} آية يوميًا'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                bookmark == null
                    ? 'ابدأ القراءة لحفظ موضعك'
                    : '$surahName · الآية ${arNum(bookmark.ayahNumber)}',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'ورد اليوم',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: secondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${arNum(percent)}٪',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              GradientProgressBar(value: data.todayFraction),
              const SizedBox(height: 6),
              Text(
                'قرأت ${arNum(data.todayRead)} من ${arNum(data.dailyTarget)} آية',
                style: theme.textTheme.bodySmall?.copyWith(color: secondary),
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
                  label: Text(
                    bookmark == null ? 'ابدأ القراءة' : 'متابعة القراءة',
                  ),
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
      useRootNavigator: true,
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
              'الهدف اليومي للقراءة',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filledTonal(
                  onPressed: () => _change(5),
                  icon: const Icon(Icons.add_rounded),
                ),
                SizedBox(
                  width: 120,
                  child: Column(
                    children: [
                      Text(
                        arNum(_value),
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Text('آية / يوم'),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () => _change(-5),
                  icon: const Icon(Icons.remove_rounded),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(_value),
                child: const Text('حفظ'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
