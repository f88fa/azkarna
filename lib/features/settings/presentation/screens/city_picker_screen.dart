import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_snack.dart';
import '../../../../core/widgets/popup_scaffold.dart';
import '../../../prayer_times/domain/entities/saudi_city.dart';
import '../../../prayer_times/presentation/providers/location_providers.dart';
import '../widgets/settings_group.dart';

/// Manual choice of a Saudi city, searchable and grouped by region.
class CityPickerScreen extends ConsumerStatefulWidget {
  const CityPickerScreen({super.key});

  @override
  ConsumerState<CityPickerScreen> createState() => _CityPickerScreenState();
}

class _CityPickerScreenState extends ConsumerState<CityPickerScreen> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _pick(SaudiCity city) async {
    HapticFeedback.selectionClick();
    await ref.read(locationProvider.notifier).setManual(city);
    if (!mounted) return;
    showAppSnack(context, 'تم اختيار ${city.name}، وحُدّثت مواقيت الصلاة.');
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(locationProvider);
    final selectedId = state.isAuto ? null : state.cityId;
    final theme = Theme.of(context);

    final regions = <String, List<SaudiCity>>{};
    for (final c in SaudiCity.all) {
      if (c.matches(_query)) (regions[c.region] ??= []).add(c);
    }

    return PopupScaffold(
      title: 'اختر مدينتك',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
            child: CupertinoSearchTextField(
              controller: _search,
              placeholder: 'ابحث عن مدينة أو منطقة',
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
            child: regions.isEmpty
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
                      for (final entry in regions.entries)
                        SettingsSection(
                          title: entry.key,
                          children: [
                            for (final city in entry.value)
                              _CityTile(
                                city: city,
                                selected: city.id == selectedId,
                                onTap: () => _pick(city),
                              ),
                          ],
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _CityTile extends StatelessWidget {
  const _CityTile({
    required this.city,
    required this.selected,
    required this.onTap,
  });

  final SaudiCity city;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return CupertinoListTile(
      backgroundColor: settingsTileColor(context),
      leadingSize: 30,
      padding: const EdgeInsetsDirectional.fromSTEB(16, 11, 16, 11),
      leading: SettingsIcon(
        icon: Icons.location_city_rounded,
        color: selected ? AppColors.primary : AppColors.teal,
      ),
      title: Text(
        city.name,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: selected ? primary : null,
        ),
      ),
      trailing: selected ? Icon(Icons.check_rounded, color: primary) : null,
      onTap: onTap,
    );
  }
}
