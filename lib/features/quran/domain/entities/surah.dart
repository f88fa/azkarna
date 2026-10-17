class Ayah {
  const Ayah({required this.number, required this.text});

  final int number;
  final String text;
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
}
