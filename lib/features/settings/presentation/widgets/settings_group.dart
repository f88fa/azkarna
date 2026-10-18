import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/arabic_format.dart';

/// Colorful icon inside a soft rounded square (iOS Settings style).
class SettingsIcon extends StatelessWidget {
  const SettingsIcon({super.key, required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.85), color],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 18, color: Colors.white),
    );
  }
}

/// iOS-style inset grouped section.
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    this.title,
    this.footer,
    required this.children,
  });

  final String? title;
  final String? footer;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.55);

    return CupertinoListSection.insetGrouped(
      backgroundColor: Colors.transparent,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      header: title == null
          ? null
          : Text(
              title!,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: muted,
              ),
            ),
      footer: footer == null
          ? null
          : Text(footer!, style: TextStyle(fontSize: 12.5, color: muted)),
      children: children,
    );
  }
}

class SettingsSwitchTile extends StatelessWidget {
  const SettingsSwitchTile({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return CupertinoListTile(
      leadingSize: 30,
      padding: const EdgeInsetsDirectional.fromSTEB(16, 11, 16, 11),
      leading: SettingsIcon(icon: icon, color: color),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: CupertinoSwitch(
        value: value,
        activeTrackColor: Theme.of(context).colorScheme.primary,
        onChanged: onChanged,
      ),
      onTap: () => onChanged(!value),
    );
  }
}

class SettingsValueTile extends StatelessWidget {
  const SettingsValueTile({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: CupertinoListTile(
        leadingSize: 30,
        padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 12),
        leading: SettingsIcon(icon: icon, color: color),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        additionalInfo: Text(value),
        trailing: onTap == null ? null : const CupertinoListTileChevron(),
        onTap: enabled ? onTap : null,
      ),
    );
  }
}

/// Row with a `- value +` stepper, used for per-prayer minute offsets.
class SettingsOffsetTile extends StatelessWidget {
  const SettingsOffsetTile({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.minutes,
    required this.onChange,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final int minutes;
  final ValueChanged<int> onChange;

  @override
  Widget build(BuildContext context) {
    return CupertinoListTile(
      leadingSize: 30,
      padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 12, 10),
      leading: SettingsIcon(icon: icon, color: color),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: _Stepper(minutes: minutes, onChange: onChange),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.minutes, required this.onChange});

  final int minutes;
  final ValueChanged<int> onChange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = minutes != 0;

    Widget button(IconData icon, int delta, String label) => Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onChange(delta);
        },
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, size: 19, color: theme.colorScheme.primary),
        ),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          button(Icons.add_rounded, 1, 'زيادة دقيقة'),
          SizedBox(
            width: 52,
            child: Text(
              active ? '${arSigned(minutes)} د' : '٠ د',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: active
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
          button(Icons.remove_rounded, -1, 'إنقاص دقيقة'),
        ],
      ),
    );
  }
}

/// Tappable row that performs an action (e.g. "send a test notification").
class SettingsActionTile extends StatelessWidget {
  const SettingsActionTile({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return CupertinoListTile(
      leadingSize: 30,
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 12),
      leading: SettingsIcon(icon: icon, color: color),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w700, color: primary),
      ),
      subtitle: subtitle == null ? null : Text(subtitle!),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
    );
  }
}

/// A row of selectable chips (single choice).
class SettingsChoiceTile<T> extends StatelessWidget {
  const SettingsChoiceTile({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
    this.enabled = true,
  });

  final IconData icon;
  final Color color;
  final String title;
  final List<T> options;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SettingsIcon(icon: icon, color: color),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in options)
                  ChoiceChip(
                    label: Text(labelOf(option)),
                    selected: option == selected,
                    showCheckmark: false,
                    selectedColor: theme.colorScheme.primary.withValues(
                      alpha: 0.16,
                    ),
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: option == selected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                    onSelected: enabled
                        ? (_) {
                            HapticFeedback.selectionClick();
                            onSelected(option);
                          }
                        : null,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
