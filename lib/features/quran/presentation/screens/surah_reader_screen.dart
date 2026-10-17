import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../khatmah/domain/entities/khatmah_progress.dart';
import '../../../khatmah/presentation/providers/khatmah_providers.dart';
import '../../domain/entities/surah.dart';
import '../providers/quran_providers.dart';
import '../../../../core/layout/layout.dart';
import '../../../../core/utils/arabic_format.dart';
import '../widgets/surah_tile.dart' show revelationTypeAr;
import '../../../../core/widgets/error_view.dart';

class SurahReaderScreen extends ConsumerStatefulWidget {
  const SurahReaderScreen({
    super.key,
    required this.surahNumber,
    this.initialAyah,
  });

  final int surahNumber;
  final int? initialAyah;

  @override
  ConsumerState<SurahReaderScreen> createState() => _SurahReaderScreenState();
}

class _SurahReaderScreenState extends ConsumerState<SurahReaderScreen> {
  final Map<int, GlobalKey> _keys = {};
  bool _didScroll = false;

  GlobalKey _keyFor(int ayah) => _keys.putIfAbsent(ayah, GlobalKey.new);

  void _scrollToInitialAyah() {
    final target = widget.initialAyah;
    if (_didScroll || target == null) return;
    _didScroll = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _keys[target]?.currentContext;
      if (context == null) return;
      Scrollable.ensureVisible(
        context,
        alignment: 0.15,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _saveBookmark(int ayah) async {
    HapticFeedback.selectionClick();
    await ref
        .read(khatmahProvider.notifier)
        .updatePosition(
          Bookmark(surahNumber: widget.surahNumber, ayahNumber: ayah),
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('تم حفظ موضع القراءة · الآية ${arNum(ayah)}'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final surah = ref.watch(surahProvider(widget.surahNumber));
    final bookmark = ref.watch(khatmahProvider).asData?.value.bookmark;
    final markedAyah = bookmark?.surahNumber == widget.surahNumber
        ? bookmark?.ayahNumber
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          surah.asData?.value.name ?? 'سورة ${arNum(widget.surahNumber)}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: surah.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(surahProvider(widget.surahNumber)),
        ),
        data: (data) {
          _scrollToInitialAyah();
          return _Reader(
            surah: data,
            markedAyah: markedAyah,
            keyFor: _keyFor,
            onAyahTap: _saveBookmark,
          );
        },
      ),
    );
  }
}

class _Reader extends StatelessWidget {
  const _Reader({
    required this.surah,
    required this.markedAyah,
    required this.keyFor,
    required this.onAyahTap,
  });

  final Surah surah;
  final int? markedAyah;
  final GlobalKey Function(int) keyFor;
  final ValueChanged<int> onAyahTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        screenBottomInset(context, extra: 32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Text(
                  surah.name,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    color: primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${revelationTypeAr(surah.revelationType)} · ${arNum(surah.ayahCount)} آيات',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          for (final ayah in surah.ayahs)
            _AyahItem(
              key: keyFor(ayah.number),
              ayah: ayah,
              isMarked: ayah.number == markedAyah,
              onTap: () => onAyahTap(ayah.number),
            ),
        ],
      ),
    );
  }
}

class _AyahItem extends StatelessWidget {
  const _AyahItem({
    super.key,
    required this.ayah,
    required this.isMarked,
    required this.onTap,
  });

  final Ayah ayah;
  final bool isMarked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: isMarked
              ? primary.withValues(alpha: 0.12)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isMarked ? primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        arNum(ayah.number),
                        style: TextStyle(
                          color: primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (isMarked)
                      Icon(Icons.bookmark_rounded, size: 20, color: primary),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  ayah.text,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.justify,
                  style: const TextStyle(fontSize: 26, height: 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
