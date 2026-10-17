import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/arabic_format.dart';
import '../../domain/entities/adhkar_category.dart';

/// Result of the editor sheet.
typedef DhikrDraft = ({String text, int count});

/// Bottom sheet to create or edit one of the user's own adhkar.
/// Returns the entered text/count, or null when dismissed.
Future<DhikrDraft?> showDhikrEditorSheet(
  BuildContext context, {
  Dhikr? initial,
}) {
  return showModalBottomSheet<DhikrDraft>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _DhikrEditorSheet(initial: initial),
  );
}

class _DhikrEditorSheet extends StatefulWidget {
  const _DhikrEditorSheet({this.initial});

  final Dhikr? initial;

  @override
  State<_DhikrEditorSheet> createState() => _DhikrEditorSheetState();
}

class _DhikrEditorSheetState extends State<_DhikrEditorSheet> {
  static const int _maxCount = 1000;

  late final _text = TextEditingController(text: widget.initial?.text);
  late int _count = widget.initial?.count ?? 1;
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _step(int delta) =>
      setState(() => _count = (_count + delta).clamp(1, _maxCount));

  void _submit() {
    final text = _text.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'اكتب نص الذكر أولًا');
      return;
    }
    Navigator.of(context).pop((text: text, count: _count));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final editing = widget.initial != null;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              editing ? 'تعديل الذكر' : 'ذكر جديد',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _text,
              autofocus: true,
              minLines: 3,
              maxLines: 8,
              textInputAction: TextInputAction.newline,
              style: const TextStyle(fontSize: 20, height: 1.8),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              decoration: InputDecoration(
                hintText: 'اكتب الذكر أو الدعاء هنا',
                errorText: _error,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'عدد التكرار',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'إنقاص',
                  onPressed: _count > 1 ? () => _step(-1) : null,
                  icon: const Icon(Icons.remove_rounded),
                ),
                SizedBox(
                  width: 64,
                  child: Text(
                    arNum(_count),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'زيادة',
                  onPressed: _count < _maxCount ? () => _step(1) : null,
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                for (final preset in const [1, 3, 7, 10, 33, 100])
                  ChoiceChip(
                    label: Text(arNum(preset)),
                    selected: _count == preset,
                    visualDensity: VisualDensity.compact,
                    onSelected: (_) {
                      HapticFeedback.selectionClick();
                      setState(() => _count = preset);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: Text(editing ? 'حفظ التعديل' : 'إضافة الذكر'),
            ),
          ],
        ),
      ),
    );
  }
}
