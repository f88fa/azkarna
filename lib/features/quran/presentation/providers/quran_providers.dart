import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/json_asset_service.dart';
import '../../data/datasources/quran_local_data_source.dart';
import '../../data/repositories/quran_repository_impl.dart';
import '../../domain/entities/surah.dart';
import '../../domain/repositories/quran_repository.dart';

final quranLocalDataSourceProvider = Provider<QuranLocalDataSource>(
  (ref) => QuranAssetDataSource(ref.watch(jsonAssetServiceProvider)),
);

final quranRepositoryProvider = Provider<QuranRepository>(
  (ref) => QuranRepositoryImpl(ref.watch(quranLocalDataSourceProvider)),
);

final surahsProvider = FutureProvider<List<Surah>>(
  (ref) => ref.watch(quranRepositoryProvider).getSurahs(),
);

final surahProvider = FutureProvider.family<Surah, int>(
  (ref, number) => ref.watch(quranRepositoryProvider).getSurah(number),
);
