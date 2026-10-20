import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/adhan_sound.dart';
import '../../domain/entities/notification_tap.dart';
import '../providers/adhan_player_provider.dart';

/// Starts the full adhan in the app when an Adhan notification is tapped
/// (including the tap that launched the app).
class AdhanPlaybackHandler extends ConsumerStatefulWidget {
  const AdhanPlaybackHandler({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AdhanPlaybackHandler> createState() =>
      _AdhanPlaybackHandlerState();
}

class _AdhanPlaybackHandlerState extends ConsumerState<AdhanPlaybackHandler> {
  @override
  void initState() {
    super.initState();
    NotificationTaps.latest.addListener(_onTap);
    // A tap that started the app arrived before this widget existed.
    WidgetsBinding.instance.addPostFrameCallback((_) => _onTap());
  }

  @override
  void dispose() {
    NotificationTaps.latest.removeListener(_onTap);
    super.dispose();
  }

  void _onTap() {
    if (!mounted) return;
    final tap = NotificationTaps.latest.value;
    final adhan = AdhanPayload.tryParse(tap?.payload);
    if (adhan == null) return;
    NotificationTaps.latest.value = null; // handled
    if (adhan.duration != AdhanDuration.full) return;
    unawaited(
      ref
          .read(adhanPlayerProvider.notifier)
          .play(adhan.sound, prayerLabel: adhan.prayerLabel),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// A bar over the whole app while the full adhan plays, with a stop button.
class AdhanNowPlayingBar extends ConsumerWidget {
  const AdhanNowPlayingBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = ref.watch(adhanPlayerProvider);
    if (playback == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Material(
            elevation: 6,
            color: scheme.primary,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsetsDirectional.only(
                start: 16,
                end: 6,
                top: 6,
                bottom: 6,
              ),
              child: Row(
                children: [
                  Icon(Icons.volume_up_rounded, color: scheme.onPrimary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          playback.title,
                          style: TextStyle(
                            color: scheme.onPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          playback.sound.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: scheme.onPrimary.withValues(alpha: 0.85),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () =>
                        ref.read(adhanPlayerProvider.notifier).stop(),
                    style: TextButton.styleFrom(
                      foregroundColor: scheme.onPrimary,
                    ),
                    icon: const Icon(Icons.stop_circle_rounded),
                    label: const Text('إيقاف'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
