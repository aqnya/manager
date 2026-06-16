import 'package:flutter/material.dart';

BorderRadius groupShape(int index, int total, {double r = 20}) {
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

class ListRow extends StatelessWidget {
  final Widget icon;
  final Widget headline;
  final Widget? supporting;
  final Widget trailing;
  final VoidCallback? onTap; // 加这个

  const ListRow({
    super.key,
    required this.icon,
    required this.headline,
    this.supporting,
    this.trailing = const SizedBox.shrink(),
    this.onTap, // 加这个
  });

  @override
  Widget build(BuildContext context) {
    final subStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

    return InkWell(
      // 包一层
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  headline,
                  if (supporting != null)
                    DefaultTextStyle.merge(
                      style: subStyle ?? const TextStyle(),
                      child: supporting!,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing,
          ],
        ),
      ),
    );
  }
}

class CardGroup extends StatelessWidget {
  final List<Widget> children;
  const CardGroup({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 2,
        children: [
          for (int i = 0; i < children.length; i++)
            CardItem(index: i, total: children.length, child: children[i]),
        ],
      ),
    );
  }
}

class CardItem extends StatelessWidget {
  final int index;
  final int total;
  final Widget child;

  const CardItem({
    super.key,
    required this.index,
    required this.total,
    required this.child,
  }) : modifier = null;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainer;
    return ClipRRect(
      borderRadius: groupShape(index, total),
      child: ColoredBox(
        color: color,
        child: Material(
          type: MaterialType.transparency,
          child: SizedBox(width: double.infinity, child: child),
        ),
      ),
    );
  }
}
