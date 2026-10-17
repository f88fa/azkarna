import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/adhkar_providers.dart';
import '../widgets/dhikr_counter_card.dart';
import '../../../../core/layout/layout.dart';
import '../../../../core/widgets/error_view.dart';

class AdhkarCategoryScreen extends ConsumerWidget {
  const AdhkarCategoryScreen({super.key, required this.categoryId});

  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(adhkarCategoryProvider(categoryId));
    final counters = ref.watch(adhkarCountersProvider);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          category.asData?.value.title ?? 'Adhkar',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (category.asData != null)
            IconButton(
              tooltip: 'Reset',
              icon: const Icon(Icons.restart_alt_rounded),
              onPressed: () => ref
                  .read(adhkarCountersProvider.notifier)
                  .resetCategory(category.asData!.value),
            ),
        ],
      ),
      body: category.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(adhkarCategoryProvider(categoryId)),
        ),
        data: (data) {
          final completed = data.adhkar
              .where((d) => (counters[d.id] ?? 0) >= d.count)
              .length;

          return ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(20, 8, 20, screenBottomInset(context)),
            itemCount: data.adhkar.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    '$completed of ${data.adhkar.length} completed',
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
                onTap: () =>
                    ref.read(adhkarCountersProvider.notifier).increment(dhikr),
              );
            },
          );
        },
      ),
    );
  }
}
