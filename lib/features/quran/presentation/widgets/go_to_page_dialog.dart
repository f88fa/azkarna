import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/arabic_format.dart';
import '../../domain/entities/quran_index.dart';

/// Asks for a Mushaf page number (1–604). Returns null when cancelled.
Future<int?> showGoToPageDialog(BuildContext context, {required int current}) {
  return showDialog<int>(
    context: context,
    useRootNavigator: true,
    builder: (_) => _GoToPageDialog(current: current),
  );
}

class _GoToPageDialog extends StatefulWidget {
  const _GoToPageDialog({required this.current});

  final int current;

  @override
  State<_GoToPageDialog> createState() => _GoToPageDialogState();
}

class _GoToPageDialogState extends State<_GoToPageDialog> {
  late final _controller = TextEditingController(text: arNum(widget.current));
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final page = parseArabicInt(_controller.text);
    if (page == null || page < 1 || page > QuranIndex.pageCount) {
      setState(
        () => _error = 'أدخل رقمًا من ١ إلى ${arNum(QuranIndex.pageCount)}',
      );
      return;
    }
    Navigator.of(context).pop(page);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('الانتقال إلى صفحة'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩]')),
          LengthLimitingTextInputFormatter(3),
        ],
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          helperText: 'صفحات المصحف: ١ – ${arNum(QuranIndex.pageCount)}',
          errorText: _error,
        ),
        onChanged: (_) {
          if (_error != null) setState(() => _error = null);
        },
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(onPressed: _submit, child: const Text('انتقال')),
      ],
    );
  }
}
