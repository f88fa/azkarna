class Dhikr {
  const Dhikr({
    required this.id,
    required this.text,
    required this.translation,
    required this.count,
    required this.reference,
  });

  final String id;
  final String text;
  final String translation;

  /// How many times the dhikr should be repeated.
  final int count;
  final String reference;
}

class AdhkarCategory {
  const AdhkarCategory({
    required this.id,
    required this.title,
    required this.titleAr,
    required this.adhkar,
  });

  final String id;
  final String title;
  final String titleAr;
  final List<Dhikr> adhkar;
}
