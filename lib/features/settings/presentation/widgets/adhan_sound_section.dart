import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_snack.dart';
import '../../../notifications/domain/entities/adhan_sound.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../../notifications/presentation/providers/sound_preview_provider.dart';
import 'settings_group.dart';

/// "Muezzin voice": pick the Adhan sound, preview it, and send a test
/// notification to hear it with the phone locked.
class AdhanSoundSection extends ConsumerWidget {
  const AdhanSoundSection({super.key, required this.selected});

  final AdhanSound selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playing = ref.watch(soundPreviewProvider);

    return SettingsSection(
      title: 'صوت المؤذن',
      footer:
          'اضغط «تجربة إشعار الأذان» ثم اقفل شاشة الجوال لتسمع الصوت المختار. '
          'تأكد أن الجوال ليس على الوضع الصامت.',
      children: [
        for (final sound in AdhanSound.values)
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
            onPreview: () =>
                ref.read(soundPreviewProvider.notifier).toggle(sound),
          ),
        SettingsActionTile(
          icon: Icons.notifications_active_rounded,
          color: AppColors.red,
          title: 'تجربة إشعار الأذان الآن (بعد ٥ ثوانٍ)',
          subtitle: 'ثم اقفل الشاشة لتسمعه',
          onTap: () async {
            await ref.read(soundPreviewProvider.notifier).stop();
            final ok = await ref
                .read(notificationSettingsProvider.notifier)
                .testAdhan();
            if (!context.mounted) return;
            showAppSnack(
              context,
              ok
                  ? 'سيصلك إشعار الأذان بعد ٥ ثوانٍ، اقفل الشاشة الآن.'
                  : 'الإشعارات محظورة. فعّلها من إعدادات النظام.',
            );
          },
        ),
      ],
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
    final isCalm = sound == AdhanSound.calm;

    return CupertinoListTile(
      leadingSize: 30,
      padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 10, 10),
      leading: SettingsIcon(
        icon: isCalm ? Icons.notifications_rounded : Icons.mosque_rounded,
        color: isCalm ? AppColors.teal : AppColors.primary,
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
                  alpha: playing ? 0.22 : 0.1,
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
          Icon(
            selected
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_off_rounded,
            color: selected ? primary : Colors.grey.shade400,
            size: 24,
          ),
        ],
      ),
      onTap: onSelect,
    );
  }
}
