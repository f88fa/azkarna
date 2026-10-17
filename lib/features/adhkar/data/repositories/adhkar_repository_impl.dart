import '../../../../core/error/failures.dart';
import '../../domain/entities/adhkar_category.dart';
import '../../domain/repositories/adhkar_repository.dart';
import '../datasources/adhkar_local_data_source.dart';

class AdhkarRepositoryImpl implements AdhkarRepository {
  const AdhkarRepositoryImpl(this._local);

  final AdhkarLocalDataSource _local;

  @override
  Future<List<AdhkarCategory>> getCategories() async {
    try {
      return await _local.loadCategories();
    } on Failure {
      rethrow;
    } on FormatException catch (e) {
      throw CacheFailure('Invalid adhkar data: ${e.message}');
    } catch (_) {
      throw const UnknownFailure();
    }
  }

  @override
  Future<AdhkarCategory> getCategory(String id) async {
    final categories = await getCategories();
    for (final category in categories) {
      if (category.id == id) return category;
    }
    throw CacheFailure('Category "$id" is not available');
  }
}
