import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/services/json_asset_service.dart';
import '../../../../core/storage/shared_preferences_provider.dart';
import '../../data/datasources/custom_adhkar_data_source.dart';
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

/// Id of the category holding the user's own adhkar.
const String customAdhkarCategoryId = 'custom';

final customAdhkarDataSourceProvider = Provider<CustomAdhkarDataSource>(
  (ref) => CustomAdhkarDataSource(ref.watch(sharedPreferencesProvider)),
);

/// The user's own adhkar ("أذكاري").
final customAdhkarProvider =
    NotifierProvider<CustomAdhkarNotifier, List<Dhikr>>(
      CustomAdhkarNotifier.new,
    );

class CustomAdhkarNotifier extends Notifier<List<Dhikr>> {
  CustomAdhkarDataSource get _store => ref.read(customAdhkarDataSourceProvider);

  @override
  List<Dhikr> build() => ref.watch(customAdhkarDataSourceProvider).load();

  Future<void> add(String text, int count) => _commit([
    ...state,
    Dhikr(
      id: 'custom_${DateTime.now().microsecondsSinceEpoch}',
      text: text.trim(),
      translation: '',
      count: count,
      reference: '',
    ),
  ]);

  Future<void> edit(String id, String text, int count) => _commit([
    for (final d in state)
      if (d.id == id)
        Dhikr(
          id: id,
          text: text.trim(),
          translation: '',
          count: count,
          reference: '',
        )
      else
        d,
  ]);

  Future<void> remove(String id) => _commit([
    for (final d in state)
      if (d.id != id) d,
  ]);

  Future<void> _commit(List<Dhikr> next) async {
    state = next;
    await _store.save(next);
  }
}

/// Built-in categories followed by the user's own "أذكاري" category.
final adhkarCategoriesProvider = FutureProvider<List<AdhkarCategory>>((
  ref,
) async {
  final builtIn = await ref.watch(adhkarRepositoryProvider).getCategories();
  final custom = ref.watch(customAdhkarProvider);
  return [
    ...builtIn,
    AdhkarCategory(
      id: customAdhkarCategoryId,
      title: 'My Adhkar',
      titleAr: 'أذكاري',
      adhkar: custom,
    ),
  ];
});

final adhkarCategoryProvider = FutureProvider.family<AdhkarCategory, String>((
  ref,
  id,
) async {
  final categories = await ref.watch(adhkarCategoriesProvider.future);
  for (final category in categories) {
    if (category.id == id) return category;
  }
  throw CacheFailure('Category "$id" is not available');
});

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
