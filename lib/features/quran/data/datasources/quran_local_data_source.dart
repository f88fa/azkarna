import '../../../../core/services/json_asset_service.dart';
import '../models/surah_model.dart';

abstract interface class QuranLocalDataSource {
  Future<List<SurahModel>> loadSurahs();
}

class QuranAssetDataSource implements QuranLocalDataSource {
  QuranAssetDataSource(this._assets);

  static const String assetPath = 'assets/json/quran.json';

  final JsonAssetService _assets;
  List<SurahModel>? _cache;

  @override
  Future<List<SurahModel>> loadSurahs() async {
    final cached = _cache;
    if (cached != null) return cached;

    final json = await _assets.load(assetPath);
    if (json is! List) throw const FormatException('Quran root must be a list');
    final surahs = json.map(SurahModel.fromJson).toList(growable: false)
      ..sort((a, b) => a.number.compareTo(b.number));
    return _cache = surahs;
  }
}
