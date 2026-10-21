import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Horizontal alignment of the popup relative to its trigger.
enum AppPopupMenuAlignment { start, end }

class AppPopupMenuItem<T> {
  const AppPopupMenuItem({
    required this.value,
    required this.label,
    this.icon,
    this.selected = false,
    this.destructive = false,
  });

  final T value;
  final String label;
  final IconData? icon;
  final bool selected;
  final bool destructive;
}

/// A compact action card used in place of Flutter's [PopupMenuButton].
///
/// The visual follows Legado's `PopupAction`: a Material 3 surface container
/// with an 8dp inset, wrapping text actions and a 240ms fade transition.
class AppPopupMenu<T> extends StatefulWidget {
  const AppPopupMenu({
    super.key,
    required this.items,
    required this.onSelected,
    this.enabled = true,
    this.icon,
    this.child,
    this.tooltip,
    this.alignment = AppPopupMenuAlignment.end,
    this.maxWidth = 340,
  }) : assert(icon != null || child != null);

  final List<AppPopupMenuItem<T>> items;
  final ValueChanged<T> onSelected;
  final bool enabled;
  final IconData? icon;
  final Widget? child;
  final String? tooltip;
  final AppPopupMenuAlignment alignment;
  final double maxWidth;

  @override
  State<AppPopupMenu<T>> createState() => _AppPopupMenuState<T>();
}

class _AppPopupMenuState<T> extends State<AppPopupMenu<T>> {
  static const _transitionDuration = Duration(milliseconds: 240);
  static const _anchorGap = 4.0;
  static const _screenMargin = 8.0;

  final _anchorKey = GlobalKey();
  bool _isOpen = false;

  Future<void> _openMenu() async {
    if (!widget.enabled || widget.items.isEmpty || _isOpen) return;
    final renderObject = _anchorKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;

    final anchor = renderObject.localToGlobal(Offset.zero) & renderObject.size;
    final safeArea = MediaQuery.viewPaddingOf(context);
    final barrierLabel = MaterialLocalizations.of(context)
        .modalBarrierDismissLabel;
    _isOpen = true;
    try {
      final selected = await showGeneralDialog<T>(
        context: context,
        barrierDismissible: true,
        barrierLabel: barrierLabel,
        barrierColor: Colors.transparent,
        transitionDuration: _transitionDuration,
        pageBuilder: (context, _, _) => SizedBox.expand(
          child: CustomSingleChildLayout(
            delegate: _AppPopupMenuLayout(
              anchor: anchor,
              alignment: widget.alignment,
              safeArea: safeArea,
              maxWidth: widget.maxWidth,
              screenMargin: _screenMargin,
              anchorGap: _anchorGap,
            ),
            child: _AppPopupMenuCard<T>(
              items: widget.items,
              onSelected: (value) => Navigator.of(context).pop(value),
            ),
          ),
        ),
        transitionBuilder: (context, animation, _, child) => FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.decelerate,
            reverseCurve: Curves.decelerate,
          ),
          child: child,
        ),
      );
      if (selected != null && mounted) widget.onSelected(selected);
    } finally {
      _isOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final icon = widget.icon;
    Widget trigger;
    if (icon != null) {
      trigger = IconButton(
        onPressed: widget.enabled ? _openMenu : null,
        icon: Icon(icon),
        tooltip: widget.tooltip,
      );
    } else {
      trigger = InkWell(
        onTap: widget.enabled ? _openMenu : null,
        child: widget.child!,
      );
      final tooltip = widget.tooltip;
      if (tooltip != null) {
        trigger = Tooltip(message: tooltip, child: trigger);
      }
    }
    return KeyedSubtree(key: _anchorKey, child: trigger);
  }
}

class _AppPopupMenuCard<T> extends StatelessWidget {
  const _AppPopupMenuCard({required this.items, required this.onSelected});

  final List<AppPopupMenuItem<T>> items;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainer,
      surfaceTintColor: Colors.transparent,
      elevation: 3,
      shadowColor: scheme.shadow.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            for (final item in items)
              _AppPopupMenuAction<T>(item: item, onSelected: onSelected),
          ],
        ),
      ),
    );
  }
}

class _AppPopupMenuAction<T> extends StatelessWidget {
  const _AppPopupMenuAction({required this.item, required this.onSelected});

  final AppPopupMenuItem<T> item;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final foreground = item.destructive
        ? scheme.error
        : item.selected
        ? scheme.onSecondaryContainer
        : scheme.onSurface;
    final background = item.selected
        ? scheme.secondaryContainer
        : Colors.transparent;
    final borderRadius = BorderRadius.circular(8);
    final icon = item.icon;

    return Semantics(
      button: true,
      selected: item.selected,
      child: Material(
        type: MaterialType.transparency,
        child: Ink(
          decoration: BoxDecoration(
            color: background,
            borderRadius: borderRadius,
          ),
          child: InkWell(
            onTap: () => onSelected(item.value),
            borderRadius: borderRadius,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 40, minWidth: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 18, color: foreground),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        item.label,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: foreground,
                          fontWeight: item.selected
                              ? FontWeight.w500
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppPopupMenuLayout extends SingleChildLayoutDelegate {
  const _AppPopupMenuLayout({
    required this.anchor,
    required this.alignment,
    required this.safeArea,
    required this.maxWidth,
    required this.screenMargin,
    required this.anchorGap,
  });

  final Rect anchor;
  final AppPopupMenuAlignment alignment;
  final EdgeInsets safeArea;
  final double maxWidth;
  final double screenMargin;
  final double anchorGap;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final availableWidth = math.max(
      0.0,
      constraints.maxWidth - safeArea.horizontal - screenMargin * 2,
    );
    final availableHeight = math.max(
      0.0,
      constraints.maxHeight - safeArea.vertical - screenMargin * 2,
    );
    return BoxConstraints(
      maxWidth: math.min(maxWidth, availableWidth),
      maxHeight: availableHeight,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final leftLimit = safeArea.left + screenMargin;
    final rightLimit = size.width - safeArea.right - screenMargin;
    final topLimit = safeArea.top + screenMargin;
    final bottomLimit = size.height - safeArea.bottom - screenMargin;

    final desiredLeft = alignment == AppPopupMenuAlignment.end
        ? anchor.right - childSize.width
        : anchor.left;
    final maxLeft = math.max(leftLimit, rightLimit - childSize.width);
    final left = desiredLeft.clamp(leftLimit, maxLeft).toDouble();

    final below = anchor.bottom + anchorGap;
    final above = anchor.top - anchorGap - childSize.height;
    double top;
    if (below + childSize.height <= bottomLimit) {
      top = below;
    } else if (above >= topLimit) {
      top = above;
    } else {
      final maxTop = math.max(topLimit, bottomLimit - childSize.height);
      top = ((topLimit + bottomLimit - childSize.height) / 2)
          .clamp(topLimit, maxTop)
          .toDouble();
    }
    return Offset(left, top);
  }

  @override
  bool shouldRelayout(_AppPopupMenuLayout oldDelegate) {
    return anchor != oldDelegate.anchor ||
        alignment != oldDelegate.alignment ||
        safeArea != oldDelegate.safeArea ||
        maxWidth != oldDelegate.maxWidth ||
        screenMargin != oldDelegate.screenMargin ||
        anchorGap != oldDelegate.anchorGap;
  }
}
