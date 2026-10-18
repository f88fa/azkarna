/// The sounds a user can pick for the Adhan notification.
///
/// Each option ships as three files that share [file] as their base name:
/// `assets/audio/<file>.wav` (in-app preview), `ios/Runner/<file>.caf` (iOS
/// notification sound, must live in the app bundle and be < 30 s) and
/// `android/app/src/main/res/raw/<file>.wav` (Android notification sound).
enum AdhanSound {
  makkah(
    id: 'makkah',
    file: 'adhan_makkah',
    label: 'أذان الحرم المكي',
    description: 'نغمة الحجاز · وقور وهادئ',
  ),
  madinah(
    id: 'madinah',
    file: 'adhan_madinah',
    label: 'أذان الحرم المدني',
    description: 'نغمة البيات · خاشع',
  ),
  afasy(
    id: 'afasy',
    file: 'adhan_afasy',
    label: 'مشاري العفاسي',
    description: 'نغمة النهاوند · عذب',
  ),
  calm(
    id: 'calm',
    file: 'adhan_calm',
    label: 'نغمة تنبيه هادئة',
    description: 'جرس ناعم وقصير',
  );

  const AdhanSound({
    required this.id,
    required this.file,
    required this.label,
    required this.description,
  });

  final String id;
  final String file;
  final String label;
  final String description;

  static const AdhanSound defaultSound = AdhanSound.makkah;

  /// Path for `AssetSource` (relative to `assets/`).
  String get previewAsset => 'audio/$file.wav';

  /// Bundle file name used by iOS notifications.
  String get iosFile => '$file.caf';

  static AdhanSound fromId(String? id) => AdhanSound.values.firstWhere(
    (s) => s.id == id,
    orElse: () => defaultSound,
  );
}
