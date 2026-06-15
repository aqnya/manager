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
    final color = Theme.of(context).colorScheme.surfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < children.length; i++)
            _CardItem(
              index: i,
              total: children.length,
              color: color,
              child: children[i],
            ),
        ],
      ),
    );
  }
}

class _CardItem extends StatelessWidget {
  final int index, total;
  final Color color;
  final Widget child;
  const _CardItem({
    required this.index,
    required this.total,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: _groupRadius(index, total),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          if (index > 0)
            Divider(
              height: 1,
              thickness: 1,
              indent: 56, // 对齐 ListTile leading 后的内容
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          child,
        ],
      ),
    );
  }
}
