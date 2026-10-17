import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../layout/layout.dart';
import 'app_backdrop.dart';

/// Chrome shared by every pop-up sheet: rounded top edge, a close (X) button,
/// a large title, and drag-down-to-dismiss on the header.
class PopupScaffold extends StatefulWidget {
  const PopupScaffold({
    super.key,
    required this.title,
    required this.child,
    this.backdrop = true,
    this.background,
    this.floatingActionButton,
  });

  final String title;
  final Widget child;

  /// Soft gradient + blobs behind the content.
  final bool backdrop;
  final Color? background;
  final Widget? floatingActionButton;

  @override
  State<PopupScaffold> createState() => _PopupScaffoldState();
}

class _PopupScaffoldState extends State<PopupScaffold>
    with SingleTickerProviderStateMixin {
  late final AnimationController _settle;

  double _offset = 0;
  double _from = 0;
  double _to = 0;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _settle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    )..addListener(_onSettle);
  }

  @override
  void dispose() {
    _settle.dispose();
    super.dispose();
  }

  void _onSettle() {
    final t = Curves.easeOutCubic.transform(_settle.value);
    setState(() => _offset = _from + (_to - _from) * t);
  }

  void _animateTo(double target, {VoidCallback? then}) {
    _from = _offset;
    _to = target;
    _settle.forward(from: 0).whenComplete(() => then?.call());
  }

  Future<void> _close() async {
    if (_closing) return;
    _closing = true;
    HapticFeedback.selectionClick();
    final popped = await Navigator.of(context).maybePop();
    if (!popped && mounted) {
      // Opened directly by URL: there is nothing underneath, go home.
      GoRouter.maybeOf(context)?.go('/');
    }
    _closing = false;
  }

  void _dragUpdate(DragUpdateDetails d) {
    if (_settle.isAnimating) _settle.stop();
    setState(() => _offset = math.max(0, _offset + d.delta.dy));
  }

  void _dragEnd(DragEndDetails d) {
    final velocity = d.primaryVelocity ?? 0;
    if (_offset > 130 || velocity > 800) {
      final height = MediaQuery.sizeOf(context).height;
      _animateTo(height, then: _close);
    } else {
      _animateTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = widget.background ?? theme.scaffoldBackgroundColor;
    final safe = MediaQuery.viewPaddingOf(context);
    final topGap = safe.top + 10;
    final bottom = safe.bottom;

    return Padding(
      padding: EdgeInsets.only(top: topGap),
      child: Transform.translate(
        offset: Offset(0, _offset),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
          child: Material(
            color: background,
            child: Stack(
              children: [
                if (widget.backdrop)
                  Positioned.fill(
                    child: const AppBackdrop(child: SizedBox.expand()),
                  ),
                Column(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onVerticalDragUpdate: _dragUpdate,
                      onVerticalDragEnd: _dragEnd,
                      child: _Header(title: widget.title, onClose: _close),
                    ),
                    Expanded(
                      child: MediaQuery.removePadding(
                        context: context,
                        removeTop: true,
                        child: NavBarInset(
                          inset: bottom + 28,
                          child: widget.child,
                        ),
                      ),
                    ),
                  ],
                ),
                if (widget.floatingActionButton != null)
                  PositionedDirectional(
                    end: 20,
                    bottom: bottom + 18,
                    child: widget.floatingActionButton!,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onClose});

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'إغلاق',
                onPressed: onClose,
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.onSurface.withValues(
                    alpha: 0.08,
                  ),
                  foregroundColor: theme.colorScheme.onSurface,
                  fixedSize: const Size(42, 42),
                ),
                icon: const Icon(Icons.close_rounded, size: 22),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
