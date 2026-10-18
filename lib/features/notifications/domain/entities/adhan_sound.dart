/// Groups shown in the muezzin picker.
enum AdhanCategory {
  haramain('الحرمان والمساجد الكبرى'),
  famous('مؤذنون مشهورون'),
  muezzins('تسجيلات أخرى'),
  calm('تكبيرات ونغمات');

  const AdhanCategory(this.label);

  final String label;
}

/// The sounds a user can pick for the Adhan notification.
///
/// All muezzin sounds are REAL recordings (sources and licences, where
/// stated, in `assets/audio/CREDITS.md`). Each option ships as three files sharing
/// `adhan_<id>` as their base name: `assets/audio/<file>.wav` (in-app
/// preview), `ios/Runner/<file>.caf` (iOS notification sound, must live in the
/// app bundle and be < 30 s) and `android/app/src/main/res/raw/<file>.wav`.
/// `tool/adhan_audio.py import <id> <file>` adds more (e.g. licensed
/// recordings of other muezzins).
enum AdhanSound {
  makkah(
    id: 'makkah_mulla',
    label: 'أذان الحرم المكي (علي أحمد ملا)',
    description: 'تسجيل حقيقي · المسجد الحرام',
    category: AdhanCategory.haramain,
    credit:
        'archive.org/details/athan_maghrib_1-6-2014_ali_mulla · بلا ترخيص معلن',
  ),
  madinah(
    id: 'madinah',
    label: 'أذان الحرم المدني',
    description: 'تسجيل حقيقي · الحرم المدني',
    category: AdhanCategory.haramain,
    credit: 'archive.org/details/azan-madinah · بلا ترخيص معلن',
  ),
  nabawi(
    id: 'nabawi',
    label: 'أذان المسجد النبوي',
    description: 'تسجيل حقيقي · المدينة المنورة',
    category: AdhanCategory.haramain,
    credit: 'ejaz215 · CC BY 3.0',
  ),
  aqsa(
    id: 'aqsa',
    label: 'أذان المسجد الأقصى',
    description: 'تسجيل حقيقي · القدس',
    category: AdhanCategory.haramain,
    credit: 'archive.org/details/youtube-Vb_O4tZytrI · بلا ترخيص معلن',
  ),
  zayed(
    id: 'zayed',
    label: 'أذان جامع الشيخ زايد',
    description: 'تسجيل حقيقي · أبوظبي',
    category: AdhanCategory.haramain,
    credit:
        'archive.org/details/MostBeautifulAzanEverHeardWhichWillMakeYouSheikhZayedGrandMosqmp3cut.net · بلا ترخيص معلن',
  ),
  afasy(
    id: 'afasy',
    label: 'أذان مشاري راشد العفاسي',
    description: 'تسجيل حقيقي',
    category: AdhanCategory.famous,
    credit: 'archive.org/details/AdhanMisharyRashid · بلا ترخيص معلن',
  ),
  qatami(
    id: 'qatami',
    label: 'أذان ناصر القطامي',
    description: 'تسجيل حقيقي',
    category: AdhanCategory.famous,
    credit: 'archive.org/details/azan-by-nasir-al-qatami · بلا ترخيص معلن',
  ),
  zahrani(
    id: 'zahrani',
    label: 'أذان منصور الزهراني',
    description: 'تسجيل حقيقي · أذان الفجر',
    category: AdhanCategory.famous,
    credit: 'archive.org/details/adhan_fajr_mansour_zahrani · بلا ترخيص معلن',
  ),
  sobhi(
    id: 'sobhi',
    label: 'أذان إسلام صبحي',
    description: 'تسجيل حقيقي',
    category: AdhanCategory.famous,
    credit: 'archive.org/details/A.S.I.S · بلا ترخيص معلن',
  ),
  sabahFakhri(
    id: 'sabah_fakhri',
    label: 'أذان صباح فخري',
    description: 'تسجيل حقيقي · بصوت الفنان صباح فخري',
    category: AdhanCategory.muezzins,
    credit: 'Sabah Fakhri · Public domain',
  ),
  maahur(
    id: 'maahur',
    label: 'أذان بمقام الماهور',
    description: 'تسجيل حقيقي · سعيد حاتم زاده',
    category: AdhanCategory.muezzins,
    credit: 'Saeed Hatamzadeh-Varmazyar · CC BY-SA 4.0',
  ),
  voice1(
    id: 'voice_1',
    label: 'أذان · مؤذن ١',
    description: 'تسجيل حقيقي لمؤذن',
    category: AdhanCategory.muezzins,
    credit: 'Aishatu98 · CC0',
  ),
  voice2(
    id: 'voice_2',
    label: 'أذان · مؤذن ٢',
    description: 'تسجيل حقيقي لمؤذن',
    category: AdhanCategory.muezzins,
    credit: 'Adam-synagda · CC0',
  ),
  takbeer(
    id: 'takbeer',
    label: 'تكبيرات الأذان فقط (مختصر)',
    description: 'من تسجيل المسجد النبوي · قصير',
    category: AdhanCategory.calm,
    credit: 'ejaz215 · CC BY 3.0',
  ),
  calm(
    id: 'calm',
    label: 'نغمة تنبيه إسلامية هادئة',
    description: 'جرس ناعم وقصير',
    category: AdhanCategory.calm,
  );

  const AdhanSound({
    required this.id,
    required this.label,
    required this.description,
    required this.category,
    this.credit,
  });

  final String id;
  final String label;
  final String description;
  final AdhanCategory category;

  /// Author and licence of the recording, if any (shown in About).
  final String? credit;

  static const AdhanSound defaultSound = AdhanSound.nabawi;

  /// Base name shared by the preview / iOS / Android files.
  String get file => 'adhan_$id';

  /// Path for `AssetSource` (relative to `assets/`).
  String get previewAsset => 'audio/$file.wav';

  /// Bundle file name used by iOS notifications.
  String get iosFile => '$file.caf';

  /// Unknown or retired ids (earlier builds) fall back to the default.
  static AdhanSound fromId(String? id) {
    for (final s in values) {
      if (s.id == id) return s;
    }
    return defaultSound;
  }

  /// Sounds of [category], in display order.
  static List<AdhanSound> inCategory(AdhanCategory category) => [
    for (final s in values)
      if (s.category == category) s,
  ];

  /// Matches [query] against the label and description; an empty query
  /// matches everything.
  bool matches(String query) {
    final q = query.trim();
    if (q.isEmpty) return true;
    return label.contains(q) || description.contains(q);
  }
}
