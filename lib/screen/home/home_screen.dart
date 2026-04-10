import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home_view_model.dart';

// ─────────────────────────────────────────────
// Glow circle
// ─────────────────────────────────────────────

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.color, required this.child, this.size = 50});
  final Color color;
  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GlowPainter(color: color),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

class _GlowPainter extends CustomPainter {
  _GlowPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 1.8;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [color.withOpacity(0.45), Colors.transparent],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(_GlowPainter old) => old.color != color;
}

// ─────────────────────────────────────────────
// StatusCard
// ─────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.status, required this.onTap});
  final InstallStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final containerColor = status == InstallStatus.installed
        ? cs.primaryContainer
        : (isDark ? cs.errorContainer : cs.error);
    final contentColor = status == InstallStatus.installed
        ? cs.onPrimaryContainer
        : (isDark ? cs.onErrorContainer : cs.onError);
    final icon = status == InstallStatus.installed
        ? Icons.check_circle
        : Icons.system_update;
    final title = status == InstallStatus.installed ? '已安装' : '未安装';
    final subtitle = status == InstallStatus.installed ? '服务运行正常' : '点击安装';

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Material(
        color: containerColor.withOpacity(0.75),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                _GlowCircle(
                  color: contentColor,
                  child: Icon(icon, color: contentColor, size: 24),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: contentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: contentColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                _GlowCircle(
                  color: contentColor,
                  size: 30,
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: contentColor.withOpacity(0.6),
                    size: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// StatCard
// ─────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.onTap,
  });
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      color: cs.surfaceContainer.withOpacity(0.65),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: cs.onSurface.withOpacity(0.55),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// DeviceInfoCard
// ─────────────────────────────────────────────

class _DeviceInfoCard extends StatelessWidget {
  const _DeviceInfoCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // TODO: 替换为 device_info_plus 真实数据
    final items = [
      (Icons.memory, '内核版本', Platform.operatingSystemVersion),
      (Icons.android, 'Android 版本', Platform.operatingSystem),
      (Icons.phone_android, '设备', Platform.localHostname),
      (Icons.settings, '管理器版本', '1.0.0'),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [cs.primary.withOpacity(0.08), Colors.transparent],
                ),
              ),
            ),
          ),
          Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            elevation: 0,
            color: cs.surfaceContainer.withOpacity(0.6),
            child: Column(
              children: List.generate(items.length, (i) {
                final (icon, title, value) = items[i];
                return Column(
                  children: [
                    _DeviceInfoItem(icon: icon, title: title, value: value),
                    if (i < items.length - 1)
                      Divider(
                        height: 0.5,
                        thickness: 0.5,
                        indent: 20,
                        endIndent: 20,
                        color: cs.outlineVariant,
                      ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceInfoItem extends StatelessWidget {
  const _DeviceInfoItem({
    required this.icon,
    required this.title,
    required this.value,
  });
  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: cs.primaryContainer.withOpacity(0.8),
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: cs.onPrimaryContainer),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: cs.onSurface.withOpacity(0.55),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// HomeScreen
// ─────────────────────────────────────────────

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    this.onNavigateToApps,
    this.onNavigateToRules,
    this.extraBottomPadding = 88,
  });
  final VoidCallback? onNavigateToApps;
  final VoidCallback? onNavigateToRules;
  final double extraBottomPadding;

  @override
  Widget build(BuildContext context) {
    const showRules = false; // TODO: 从 preferences 读取

    final vm = context.watch<HomeViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'NekoSU',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 12, 16, extraBottomPadding),
        child: Column(
          children: [
            _StatusCard(
              status: vm.installStatus,
              onTap: () {
                if (vm.installStatus != InstallStatus.installed) {
                  // TODO: show install sheet
                } else {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('服务运行正常')));
                }
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: '超级用户',
                    value: vm.suCount.toString(),
                    onTap: () => onNavigateToApps?.call(),
                  ),
                ),
                if (showRules) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'FMAC 规则',
                      value: vm.ruleCount.toString(),
                      onTap: () => onNavigateToRules?.call(),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            const _DeviceInfoCard(),
          ],
        ),
      ),
    );
  }
}
