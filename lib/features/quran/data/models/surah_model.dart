import '../../domain/entities/surah.dart';

class AyahModel extends Ayah {
  const AyahModel({
    required super.number,
    required super.text,
    required super.page,
    required super.juz,
  });

  /// Compact asset format: `{n: number, t: text, p: page, j: juz}`.
  factory AyahModel.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid ayah');
    }
    final number = json['n'];
    final text = json['t'];
    final page = json['p'];
    final juz = json['j'];
    if (number is! int || text is! String || page is! int || juz is! int) {
      throw const FormatException('Invalid ayah fields');
    }
    return AyahModel(number: number, text: text, page: page, juz: juz);
  }
}

class SurahModel extends Surah {
  const SurahModel({
    required super.number,
    required super.name,
    required super.englishName,
    required super.revelationType,
    required super.ayahs,
  });

  factory SurahModel.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid surah');
    }
    final number = json['number'];
    final name = json['name'];
    final englishName = json['englishName'];
    final ayahs = json['ayahs'];
    if (number is! int ||
        name is! String ||
        englishName is! String ||
        ayahs is! List) {
      throw const FormatException('Invalid surah fields');
    }
    return SurahModel(
      number: number,
      name: name,
      englishName: englishName,
      revelationType: json['revelationType'] as String? ?? '',
      ayahs: ayahs.map(AyahModel.fromJson).toList(growable: false),
    );
  }
}
