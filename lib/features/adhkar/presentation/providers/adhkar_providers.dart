import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/json_asset_service.dart';
import '../../data/datasources/adhkar_local_data_source.dart';
import '../../data/repositories/adhkar_repository_impl.dart';
import '../../domain/entities/adhkar_category.dart';
import '../../domain/repositories/adhkar_repository.dart';

final adhkarLocalDataSourceProvider = Provider<AdhkarLocalDataSource>(
  (ref) => AdhkarAssetDataSource(ref.watch(jsonAssetServiceProvider)),
);

final adhkarRepositoryProvider = Provider<AdhkarRepository>(
  (ref) => AdhkarRepositoryImpl(ref.watch(adhkarLocalDataSourceProvider)),
);

final adhkarCategoriesProvider = FutureProvider<List<AdhkarCategory>>(
  (ref) => ref.watch(adhkarRepositoryProvider).getCategories(),
);

final adhkarCategoryProvider = FutureProvider.family<AdhkarCategory, String>(
  (ref, id) => ref.watch(adhkarRepositoryProvider).getCategory(id),
);

/// In-session repetition counters keyed by dhikr id.
final adhkarCountersProvider =
    NotifierProvider<AdhkarCountersNotifier, Map<String, int>>(
      AdhkarCountersNotifier.new,
    );

class AdhkarCountersNotifier extends Notifier<Map<String, int>> {
  @override
  Map<String, int> build() => const {};

  void increment(Dhikr dhikr) {
    final current = state[dhikr.id] ?? 0;
    if (current >= dhikr.count) return;
    state = {...state, dhikr.id: current + 1};
  }

  void resetCategory(AdhkarCategory category) {
    final next = {...state};
    for (final dhikr in category.adhkar) {
      next.remove(dhikr.id);
    }
    state = next;
  }
}
