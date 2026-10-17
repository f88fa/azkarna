import '../../domain/entities/adhkar_category.dart';

class DhikrModel extends Dhikr {
  const DhikrModel({
    required super.id,
    required super.text,
    required super.translation,
    required super.count,
    required super.reference,
  });

  factory DhikrModel.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid dhikr');
    }
    final id = json['id'];
    final text = json['text'];
    if (id is! String || text is! String) {
      throw const FormatException('Invalid dhikr fields');
    }
    final count = json['count'];
    return DhikrModel(
      id: id,
      text: text,
      translation: json['translation'] as String? ?? '',
      count: count is int && count > 0 ? count : 1,
      reference: json['reference'] as String? ?? '',
    );
  }
}

class AdhkarCategoryModel extends AdhkarCategory {
  const AdhkarCategoryModel({
    required super.id,
    required super.title,
    required super.titleAr,
    required super.adhkar,
  });

  factory AdhkarCategoryModel.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid category');
    }
    final id = json['id'];
    final title = json['title'];
    final adhkar = json['adhkar'];
    if (id is! String || title is! String || adhkar is! List) {
      throw const FormatException('Invalid category fields');
    }
    return AdhkarCategoryModel(
      id: id,
      title: title,
      titleAr: json['titleAr'] as String? ?? '',
      adhkar: adhkar.map(DhikrModel.fromJson).toList(growable: false),
    );
  }
}
