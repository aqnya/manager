import 'package:flutter/material.dart';

BorderRadius _groupRadius(int index, int total, {double r = 20}) {
  if (total <= 1) return BorderRadius.circular(r);
  if (index == 0)
    return BorderRadius.only(
      topLeft: Radius.circular(r),
      topRight: Radius.circular(r),
    );
  if (index == total - 1)
    return BorderRadius.only(
      bottomLeft: Radius.circular(r),
      bottomRight: Radius.circular(r),
    );
  return BorderRadius.zero;
}

class CardGroup extends StatelessWidget {
  final List<Widget> children;
  const CardGroup({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).colorScheme.surfaceContainerHigh;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 4),
            _CardItem(
              index: i,
              total: children.length,
              color: bgColor,
              child: children[i],
            ),
          ],
        ],
      ),
    );
  }
}

class _CardItem extends StatelessWidget {
  final int index, total;
  final Color color;
  const _CardItem({
    required this.index,
    required this.total,
    required this.color,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: _groupRadius(index, total),
      child: ColoredBox(
        color: color,
        child: Material(
          type: MaterialType.transparency,
          child: child,
        ),
      ),
    );
  }
}