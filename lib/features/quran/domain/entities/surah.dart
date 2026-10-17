class Ayah {
  const Ayah({
    required this.number,
    required this.text,
    required this.page,
    required this.juz,
  });

  /// Number inside its surah (1-based), as printed in the Mushaf.
  final int number;
  final String text;

  /// Page of the Madani Mushaf (1–604) on which the ayah starts.
  final int page;
  final int juz;
}

class Surah {
  const Surah({
    required this.number,
    required this.name,
    required this.englishName,
    required this.revelationType,
    required this.ayahs,
  });

  final int number;
  final String name;
  final String englishName;
  final String revelationType;
  final List<Ayah> ayahs;

  int get ayahCount => ayahs.length;

  /// Page of the Mushaf on which the surah begins.
  int get startPage => ayahs.first.page;

  /// Every surah is introduced by the Basmalah line except Al-Fatihah (where
  /// it is ayah 1) and At-Tawbah (which has none).
  bool get hasBismillahHeader => number != 1 && number != 9;

  /// Page on which [ayah] is printed, or [startPage] for unknown numbers.
  int pageOf(int ayah) {
    if (ayah < 1 || ayah > ayahs.length) return startPage;
    return ayahs[ayah - 1].page;
  }
}
