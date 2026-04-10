import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home_view_model.dart';
import 'dart:ui' as ui;

// ─────────────────────────────────────────────
// StatusCard
// KT: containerColor.copy(alpha = 0.75f)
// KT: contentColor.copy(alpha = opacity=0.06f) 用于图标背景
// KT: contentColor.copy(alpha = 0.45f) 用于 glow
// KT: contentColor.copy(alpha = 0.7f)  用于 subtitle
// KT: contentColor.copy(alpha = 0.6f)  用于箭头图标
// KT: contentColor.copy(alpha = 0.35f) 用于箭头 glow (右侧小圆)
// ─────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.status, required this.onTap});
  final InstallStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // KT: background.luminance() < 0.5f
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // KT: NOT_INSTALLED → dark=errorContainer/onErrorContainer, light=error/onError
    final containerColor = status == InstallStatus.installed
        ? cs.primaryContainer
        : (isDark ? cs.errorContainer : cs.error);
    final contentColor = status == InstallStatus.installed
        ? cs.onPrimaryContainer
        : (isDark ? cs.onErrorContainer : cs.onError);
    final icon = status == InstallStatus.installed ? Icons.check_circle : Icons.system_update;
    final title = status == InstallStatus.installed ? '已安装' : '未安装';
    final subtitle = status == InstallStatus.installed ? '服务运行正常' : '点击安装';

    // KT: opacity = 0.06f (默认参数)
    const opacity = 0.06;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Material(
        // KT: containerColor.copy(alpha = 0.75f)
        color: containerColor.withOpacity(0.75),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
child: Row(
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [
                // KT: size=50dp, background(contentColor.copy(alpha=opacity)), glow(alpha=0.45f)
                _GlowCircle(
                  color: contentColor,
                  glowAlpha: 0.45,
                  bgAlpha: opacity,
                  size: 50,
                  child: Icon(icon, color: contentColor, size: 24),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // KT: titleMedium, FontWeight.SemiBold, color=contentColor
                    Text(title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: contentColor, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 3),
                    // KT: bodySmall, contentColor.copy(alpha=0.7f)
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: contentColor.withOpacity(0.7))),
                  ],
                ),
                const Spacer(),
                // KT: size=30dp, background(alpha=opacity), glow(alpha=0.35f), icon(alpha=0.6f)
                _GlowCircle(
                  color: contentColor,
                  glowAlpha: 0.35,
                  bgAlpha: opacity,
                  size: 30,
                  child: Icon(Icons.arrow_forward_ios,
                      color: contentColor.withOpacity(0.6), size: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// KT 的 drawBehind glow + background circle 组合
class _GlowCircle extends StatelessWidget {
  const _GlowCircle({
    required this.color,
    required this.child,
    required this.glowAlpha,
    required this.bgAlpha,
    this.size = 50,
  });
  final Color color;
  final Widget child;
  final double glowAlpha;
  final double bgAlpha;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GlowPainter(color: color, glowAlpha: glowAlpha),
      child: Container(
        width: size,
        height: size,
        // KT: background(color = contentColor.copy(alpha = opacity), shape = CircleShape)
        decoration: BoxDecoration(
          color: color.withOpacity(bgAlpha),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

class _GlowPainter extends CustomPainter {
  _GlowPainter({required this.color, required this.glowAlpha});
  final Color color;
  final double glowAlpha;

  @override
  void paint(Canvas canvas, Size size) {
    // KT: glowRadius = size.minDimension / 1.8f
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 1.8;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          // KT: listOf(contentColor.copy(alpha=glowAlpha), Color.Transparent)
          colors: [color.withOpacity(glowAlpha), Colors.transparent],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(_GlowPainter old) => old.color != color || old.glowAlpha != glowAlpha;
}

// ─────────────────────────────────────────────
// StatCard
// KT: surfaceContainer.copy(alpha = 0.65f)
// KT: onSurface (value), onSurface.copy(alpha=0.55f) (label)
// ─────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.onTap});
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      // KT: surfaceContainer.copy(alpha = 0.65f)
      color: cs.surfaceContainer.withOpacity(0.65),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // KT: headlineMedium, FontWeight.Bold, onSurface
              Text(value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold, color: cs.onSurface)),
              const SizedBox(height: 10),
              // KT: labelMedium, onSurface.copy(alpha=0.55f)
              Text(label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: cs.onSurface.withOpacity(0.55))),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// DeviceInfoCard
// KT: primary.copy(alpha=0.08f) verticalGradient + blur(24dp) 背景层
// KT: surfaceContainer.copy(alpha=0.6f) 卡片色
// KT: primaryContainer.copy(alpha=0.8f) 图标背景
// KT: onPrimaryContainer 图标色
// KT: onSurface.copy(alpha=0.55f) title色
// KT: onSurface value色, FontWeight.SemiBold
// ─────────────────────────────────────────────

class _DeviceInfoCard extends StatelessWidget {
  const _DeviceInfoCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // TODO: 替换为 device_info_plus 真实数据
    // KT: os.version / Build.VERSION.RELEASE / MANUFACTURER+MODEL / appVersion
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
          // KT: matchParentSize + verticalGradient(primary 0.08→transparent) + blur(24dp)
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: _blurFilter,
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
          ),
          // KT: surfaceContainer.copy(alpha=0.6f)
          Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            elevation: 0,
            color: cs.surfaceContainer.withOpacity(0.6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: List.generate(items.length, (i) {
                  final (icon, title, value) = items[i];
                  return Column(
                    children: [
                      _DeviceInfoItem(icon: icon, title: title, value: value),
                      if (i < items.length - 1)
                        Divider(
                          height: 0.5, thickness: 0.5,
                          indent: 20, endIndent: 20,
                          // KT: outlineVariant
                          color: cs.outlineVariant,
                        ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static final _blurFilter = ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24);
}

class _DeviceInfoItem extends StatelessWidget {
  const _DeviceInfoItem({required this.icon, required this.title, required this.value});
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
          // KT: size=38dp, primaryContainer.copy(alpha=0.8f), RoundedCornerShape(11dp)
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: cs.primaryContainer.withOpacity(0.8),
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: cs.onPrimaryContainer),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // KT: labelMedium, onSurface.copy(alpha=0.55f), FontWeight.Medium
                Text(title,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: cs.onSurface.withOpacity(0.55),
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                // KT: bodyMedium, onSurface, FontWeight.SemiBold
                Text(value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurface, fontWeight: FontWeight.w600)),
              ],
            ),
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
    const showRules = false;
    final vm = context.watch<HomeViewModel>();

    return Scaffold(
      appBar: AppBar(
        // KT: titleLarge, FontWeight.Bold
        title: const Text('NekoSU', style: TextStyle(fontWeight: FontWeight.bold)),
        // KT: containerColor=surface, titleContentColor=onSurface
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        // KT: horizontal=16, vertical=12, bottom=88
        padding: EdgeInsets.fromLTRB(16, 12, 16, extraBottomPadding),
        child: Column(
          // KT: verticalArrangement = spacedBy(16.dp)
          children: [
            _StatusCard(
              status: vm.installStatus,
              onTap: () {
                if (vm.installStatus != InstallStatus.installed) {
                  // TODO: install sheet
                } else {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('服务运行正常')));
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
