import 'package:flutter/material.dart';

import '../../domain/entities/surah.dart';

class SurahTile extends StatelessWidget {
  const SurahTile({super.key, required this.surah, required this.onTap});

  final Surah surah;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final secondary = theme.colorScheme.onSurface.withValues(alpha: 0.55);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${surah.number}',
                  style: TextStyle(color: primary, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      surah.englishName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${surah.revelationType} · ${surah.ayahCount} ayahs',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: secondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                surah.name,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
