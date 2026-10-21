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
  final VoidCallback? onTap;

  const ListRow({
    super.key,
    required this.icon,
    required this.headline,
    this.supporting,
    this.trailing = const SizedBox.shrink(),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final headlineStyle = textTheme.bodyLarge;
    final subStyle = textTheme.bodyMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

    return InkWell(
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
                  DefaultTextStyle.merge(
                    style: headlineStyle ?? const TextStyle(),
                    child: headline,
                  ),
                  if (supporting != null) ...[
                    const SizedBox(height: 2),
                    DefaultTextStyle.merge(
                      style: subStyle ?? const TextStyle(),
                      child: supporting!,
                    ),
                  ],
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
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceBright;
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
