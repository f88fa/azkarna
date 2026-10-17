import '../entities/adhkar_category.dart';

abstract interface class AdhkarRepository {
  /// Throws a `Failure` on error.
  Future<List<AdhkarCategory>> getCategories();
  Future<AdhkarCategory> getCategory(String id);
}
