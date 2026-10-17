import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/adhkar_providers.dart';
import '../../domain/entities/adhkar_category.dart';
import '../widgets/dhikr_counter_card.dart';
import '../widgets/dhikr_editor_sheet.dart';
import '../../../../core/layout/layout.dart';
import '../../../../core/utils/arabic_format.dart';
import '../../../../core/widgets/app_backdrop.dart';
import '../../../../core/widgets/error_view.dart';

Future<void> _add(BuildContext context, WidgetRef ref) async {
  final draft = await showDhikrEditorSheet(context);
  if (draft == null) return;
  await ref.read(customAdhkarProvider.notifier).add(draft.text, draft.count);
}

class AdhkarCategoryScreen extends ConsumerWidget {
  const AdhkarCategoryScreen({super.key, required this.categoryId});

  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(adhkarCategoryProvider(categoryId));
    final counters = ref.watch(adhkarCountersProvider);

    final isCustom = categoryId == customAdhkarCategoryId;

    return Scaffold(
      floatingActionButton: isCustom
          ? FloatingActionButton.extended(
              onPressed: () => _add(context, ref),
              icon: const Icon(Icons.add_rounded),
              label: const Text('إضافة ذكر'),
            )
          : null,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          category.asData?.value.titleAr ?? 'الأذكار',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (category.asData != null)
            IconButton(
              tooltip: 'إعادة التصفير',
              icon: const Icon(Icons.restart_alt_rounded),
              onPressed: () => ref
                  .read(adhkarCountersProvider.notifier)
                  .resetCategory(category.asData!.value),
            ),
        ],
      ),
      body: AppBackdrop(
        child: category.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ErrorView(
            error: error,
            onRetry: () => ref.invalidate(adhkarCategoryProvider(categoryId)),
          ),
          data: (data) {
            if (isCustom && data.adhkar.isEmpty) {
              return const _EmptyCustom();
            }
            final completed = data.adhkar
                .where((d) => (counters[d.id] ?? 0) >= d.count)
                .length;

            return ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                screenBottomInset(context) + (isCustom ? 72 : 0),
              ),
              itemCount: data.adhkar.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsetsDirectional.only(start: 4),
                    child: Text(
                      'اكتمل ${arNum(completed)} من ${arNum(data.adhkar.length)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  );
                }
                final dhikr = data.adhkar[index - 1];
                return DhikrCounterCard(
                  dhikr: dhikr,
                  current: counters[dhikr.id] ?? 0,
                  onTap: () => ref
                      .read(adhkarCountersProvider.notifier)
                      .increment(dhikr),
                  menu: isCustom ? _DhikrMenu(dhikr: dhikr) : null,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _DhikrMenu extends ConsumerWidget {
  const _DhikrMenu({required this.dhikr});

  final Dhikr dhikr;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      tooltip: 'خيارات',
      icon: Icon(
        Icons.more_horiz_rounded,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
      ),
      onSelected: (action) async {
        final notifier = ref.read(customAdhkarProvider.notifier);
        if (action == 'edit') {
          final draft = await showDhikrEditorSheet(context, initial: dhikr);
          if (draft != null) {
            await notifier.edit(dhikr.id, draft.text, draft.count);
          }
        } else {
          await notifier.remove(dhikr.id);
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'edit', child: Text('تعديل')),
        PopupMenuItem(value: 'delete', child: Text('حذف')),
      ],
    );
  }
}

class _EmptyCustom extends StatelessWidget {
  const _EmptyCustom();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_rounded,
              size: 60,
              color: theme.colorScheme.primary.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 12),
            Text('لا توجد أذكار بعد', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'اضغط «إضافة ذكر» لتكتب أذكارك وأدعيتك الخاصة',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
