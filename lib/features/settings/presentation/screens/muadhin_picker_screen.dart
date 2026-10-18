import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_snack.dart';
import '../../../../core/widgets/popup_scaffold.dart';
import '../../../notifications/domain/entities/adhan_sound.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../../notifications/presentation/providers/sound_preview_provider.dart';
import '../widgets/settings_group.dart';

/// The muezzin library: search, grouped categories, a preview button on every
/// row and a check mark in front of the selected one.
class MuadhinPickerScreen extends ConsumerStatefulWidget {
  const MuadhinPickerScreen({super.key});

  @override
  ConsumerState<MuadhinPickerScreen> createState() =>
      _MuadhinPickerScreenState();
}

class _MuadhinPickerScreenState extends ConsumerState<MuadhinPickerScreen> {
  final TextEditingController _search = TextEditingController();
  late final SoundPreviewNotifier _preview;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _preview = ref.read(soundPreviewProvider.notifier);
  }

  @override
  void dispose() {
    _search.dispose();
    // Stop any preview that is still playing once the page is gone.
    Future.microtask(_preview.stop);
    super.dispose();
  }

  Future<void> _test() async {
    await _preview.stop();
    final ok = await ref
        .read(notificationSettingsProvider.notifier)
        .testAdhan();
    if (!mounted) return;
    showAppSnack(
      context,
      ok
          ? 'سيصلك إشعار الأذان بعد ٥ ثوانٍ، اقفل الشاشة الآن.'
          : 'الإشعارات محظورة. فعّلها من إعدادات النظام.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(
      notificationSettingsProvider.select(
        (s) => s.asData?.value.adhanSound ?? AdhanSound.defaultSound,
      ),
    );
    final playing = ref.watch(soundPreviewProvider);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    final sounds = [
      for (final s in AdhanSound.values)
        if (s.matches(_query)) s,
    ];

    return PopupScaffold(
      title: 'صوت المؤذن',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
            child: CupertinoSearchTextField(
              controller: _search,
              placeholder: 'ابحث عن مؤذن',
              style: TextStyle(
                fontFamily: theme.textTheme.bodyLarge?.fontFamily,
                color: theme.colorScheme.onSurface,
              ),
              placeholderStyle: TextStyle(
                fontFamily: theme.textTheme.bodyLarge?.fontFamily,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              backgroundColor: settingsTileColor(context),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: sounds.isEmpty
                ? Center(
                    child: Text(
                      'لا توجد نتائج مطابقة',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  )
                : ListView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.only(top: 4, bottom: 12),
                    children: [
                      SettingsSection(
                        title: 'المؤذنون',
                        children: [
                          for (final sound in sounds)
                            _SoundTile(
                              sound: sound,
                              selected: sound == selected,
                              playing: playing == sound,
                              onSelect: () {
                                HapticFeedback.selectionClick();
                                ref
                                    .read(notificationSettingsProvider.notifier)
                                    .setAdhanSound(sound);
                              },
                              onPreview: () => _preview.toggle(sound),
                            ),
                        ],
                      ),
                    ],
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            child: FilledButton.icon(
              onPressed: _test,
              style: FilledButton.styleFrom(
                backgroundColor: primary,
                minimumSize: const Size.fromHeight(50),
              ),
              icon: const Icon(Icons.notifications_active_rounded),
              label: const Text('تجربة إشعار الأذان الآن (بعد ٥ ثوانٍ)'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoundTile extends StatelessWidget {
  const _SoundTile({
    required this.sound,
    required this.selected,
    required this.playing,
    required this.onSelect,
    required this.onPreview,
  });

  final AdhanSound sound;
  final bool selected;
  final bool playing;
  final VoidCallback onSelect;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return CupertinoListTile(
      backgroundColor: settingsTileColor(context),
      leadingSize: 30,
      padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 10, 10),
      leading: SettingsIcon(
        icon: Icons.mosque_rounded,
        color: AppColors.primary,
      ),
      title: Text(
        sound.label,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: selected ? primary : null,
        ),
      ),
      subtitle: Text(sound.description),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            button: true,
            label: playing ? 'إيقاف المعاينة' : 'معاينة الصوت',
            child: IconButton.filledTonal(
              onPressed: onPreview,
              visualDensity: VisualDensity.compact,
              style: IconButton.styleFrom(
                backgroundColor: primary.withValues(
                  alpha: playing ? 0.24 : 0.12,
                ),
                foregroundColor: primary,
              ),
              icon: Icon(
                playing ? Icons.stop_rounded : Icons.play_arrow_rounded,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 26,
            child: selected
                ? Icon(Icons.check_circle_rounded, color: primary, size: 26)
                : null,
          ),
        ],
      ),
      onTap: onSelect,
    );
  }
}
