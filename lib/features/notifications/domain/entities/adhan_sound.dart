/// What the Adhan notification plays (chosen in the settings): the opening
/// of the adhan (up to 28 s) or only its first two takbeers.
enum AdhanDuration {
  full('كامل', 'اضغط الإشعار لسماعه كاملًا'),
  short('تكبيرتان', 'التكبيرتان الأوليان فقط');

  const AdhanDuration(this.label, this.hint);

  final String label;
  final String hint;

  /// Suffix of the bundled notification file.
  String get suffix => this == short ? '_short' : '';

  static AdhanDuration fromName(String? name) => AdhanDuration.values
      .firstWhere((d) => d.name == name, orElse: () => AdhanDuration.full);
}

/// The sounds a user can pick for the Adhan notification.
///
/// All of them are real muezzin recordings supplied with the app (source files
/// in `mp3/`). Each option ships as three files sharing `adhan_<id>` as their
/// base name: `assets/audio/<file>.wav` (in-app preview), `ios/Runner/<file>.caf`
/// (iOS notification sound, must live in the app bundle and be < 30 s) and
/// `android/app/src/main/res/raw/<file>.wav`. `tool/adhan_audio.py` converts
/// them (`folder` or `import <id> <file>`).
enum AdhanSound {
  aliMulla(
    id: 'ali_mulla',
    label: 'أذان علي بن أحمد ملا',
    description: 'تسجيل حقيقي',
  ),
  aliMulla2(
    id: 'ali_mulla_2',
    label: 'أذان علي ملا (تسجيل ثانٍ)',
    description: 'تسجيل حقيقي',
  ),
  hadrawi(
    id: 'hadrawi',
    label: 'أذان فاروق عبد الرحمن حضراوي',
    description: 'تسجيل حقيقي',
  ),
  dagriri(
    id: 'dagriri',
    label: 'أذان حمد الدغريري',
    description: 'تسجيل حقيقي',
  ),
  abdulbasit(
    id: 'abdulbasit',
    label: 'أذان الشيخ عبدالباسط',
    description: 'تسجيل حقيقي',
  ),
  qatami(id: 'qatami', label: 'أذان ناصر القطامي', description: 'تسجيل حقيقي'),
  dosari(id: 'dosari', label: 'أذان ياسر الدوسري', description: 'تسجيل حقيقي'),
  nasserObaid(
    id: 'nasser_obaid',
    label: 'أذان ناصر العبيد',
    description: 'تسجيل حقيقي',
  ),
  ramadanSaad(
    id: 'ramadan_saad',
    label: 'أذان محمد رمضان سعد',
    description: 'تسجيل حقيقي',
  ),
  basaad(id: 'basaad', label: 'أذان محمد باسعد', description: 'تسجيل حقيقي'),
  ibrahimMadani(
    id: 'ibrahim_madani',
    label: 'أذان إبراهيم المدني',
    description: 'تسجيل حقيقي',
  ),
  husseinShahat(
    id: 'hussein_shahat',
    label: 'أذان حسين شحات',
    description: 'تسجيل حقيقي',
  ),
  suhailHafez(
    id: 'suhail_hafez',
    label: 'أذان سهيل حافظ',
    description: 'تسجيل حقيقي',
  ),
  rajhi(id: 'rajhi', label: 'أذان جامع الراجحي', description: 'تسجيل حقيقي');

  const AdhanSound({
    required this.id,
    required this.label,
    required this.description,
  });

  final String id;
  final String label;
  final String description;

  static const AdhanSound defaultSound = AdhanSound.aliMulla;

  /// Base name shared by the preview / iOS / Android files.
  String get file => 'adhan_$id';

  /// Path for `AssetSource` (relative to `assets/`).
  String get previewAsset => 'audio/$file.wav';

  /// The whole adhan (2-5 min) played inside the app after tapping the
  /// notification: a notification sound is limited to 30 s by iOS.
  String get fullAsset => 'audio/full/$file.m4a';

  /// Bundle file name used by iOS notifications (full version).
  String get iosFile => '$file.caf';

  /// Notification file base name for [duration] (`adhan_<id>[_short]`): the
  /// Android raw resource and, with `.caf`, the iOS bundle file.
  String fileFor(AdhanDuration duration) => '$file${duration.suffix}';
  String iosFileFor(AdhanDuration duration) => '${fileFor(duration)}.caf';

  /// Unknown or retired ids (earlier builds) fall back to the default.
  static AdhanSound fromId(String? id) {
    for (final s in values) {
      if (s.id == id) return s;
    }
    return defaultSound;
  }

  /// Matches [query] against the label; an empty query matches everything.
  bool matches(String query) {
    final q = query.trim();
    if (q.isEmpty) return true;
    return label.contains(q) || description.contains(q);
  }
}
