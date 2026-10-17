import '../../../../core/services/json_asset_service.dart';
import '../models/adhkar_model.dart';

abstract interface class AdhkarLocalDataSource {
  Future<List<AdhkarCategoryModel>> loadCategories();
}

class AdhkarAssetDataSource implements AdhkarLocalDataSource {
  AdhkarAssetDataSource(this._assets);

  static const String assetPath = 'assets/json/adhkar.json';

  final JsonAssetService _assets;
  List<AdhkarCategoryModel>? _cache;

  @override
  Future<List<AdhkarCategoryModel>> loadCategories() async {
    final cached = _cache;
    if (cached != null) return cached;

    final json = await _assets.load(assetPath);
    final categories = json is Map<String, dynamic> ? json['categories'] : null;
    if (categories is! List) {
      throw const FormatException('Missing "categories" list');
    }
    return _cache = categories
        .map(AdhkarCategoryModel.fromJson)
        .toList(growable: false);
  }
}
