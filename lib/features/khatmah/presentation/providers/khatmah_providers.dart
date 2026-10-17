import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/shared_preferences_provider.dart';
import '../../../quran/presentation/providers/quran_providers.dart';
import '../../data/datasources/khatmah_local_data_source.dart';
import '../../data/repositories/khatmah_repository_impl.dart';
import '../../domain/entities/khatmah_progress.dart';
import '../../domain/repositories/khatmah_repository.dart';
import '../../domain/usecases/update_reading_position.dart';

final khatmahLocalDataSourceProvider = Provider<KhatmahLocalDataSource>(
  (ref) => SharedPrefsKhatmahDataSource(ref.watch(sharedPreferencesProvider)),
);

final khatmahRepositoryProvider = Provider<KhatmahRepository>(
  (ref) => KhatmahRepositoryImpl(ref.watch(khatmahLocalDataSourceProvider)),
);

final updateReadingPositionProvider = Provider<UpdateReadingPosition>(
  (ref) => UpdateReadingPosition(
    ref.watch(khatmahRepositoryProvider),
    ref.watch(quranRepositoryProvider),
  ),
);

final khatmahProvider = AsyncNotifierProvider<KhatmahNotifier, KhatmahProgress>(
  KhatmahNotifier.new,
);

class KhatmahNotifier extends AsyncNotifier<KhatmahProgress> {
  KhatmahRepository get _repository => ref.read(khatmahRepositoryProvider);

  @override
  Future<KhatmahProgress> build() =>
      ref.watch(khatmahRepositoryProvider).getProgress();

  Future<void> updatePosition(Bookmark bookmark) async {
    await ref.read(updateReadingPositionProvider).call(bookmark);
    state = AsyncData(await _repository.getProgress());
  }

  Future<void> setDailyTarget(int ayahs) async {
    await _repository.saveDailyTarget(ayahs);
    state = AsyncData(await _repository.getProgress());
  }
}
