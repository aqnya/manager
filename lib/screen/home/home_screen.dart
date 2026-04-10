import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home_view_model.dart';

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.status, required this.onTap});
  final InstallStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isInstalled = status == InstallStatus.installed;

    // 颜色配置
    final containerColor = isInstalled
        ? cs.primaryContainer
        : (isDark ? cs.errorContainer : cs.error);
    final contentColor = isInstalled
        ? cs.onPrimaryContainer
        : (isDark ? cs.onErrorContainer : cs.onError);

    final icon = isInstalled ? Icons.check_circle : Icons.system_update;
    final title = isInstalled ? '已安装' : '未安装';
    final subtitle = isInstalled ? '服务运行正常' : '点击安装';

    const opacity = 0.06;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: containerColor.withOpacity(0.75),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _GlowCircle(
                  color: contentColor,
                  glowAlpha: 0.45,
                  bgAlpha: opacity,
                  size: 50,
                  child: Icon(icon, color: contentColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: contentColor,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: contentColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                _GlowCircle(
                  color: contentColor,
                  glowAlpha: 0.35,
                  bgAlpha: opacity,
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

// 优化：使用 BoxShadow 替代 CustomPaint 渲染发光效果，更加自然且性能更好
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
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(bgAlpha),
        shape: BoxShape.circle,
        // 利用阴影实现外发光 (Glow)
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(glowAlpha),
            blurRadius: size / 2.5, // 动态模糊半径
            spreadRadius: 0,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: child,
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
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainer.withOpacity(0.65),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
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
                const SizedBox(height: 8),
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

    return Stack(
      children: [
        // 优化：去除无意义的 ImageFilter 模糊渐变，改为真实的底部环境光投影（Ambient Shadow）
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),
        // 主卡片
        Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainer.withOpacity(0.6),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: cs.outlineVariant.withOpacity(0.3), // 增加一层极细的微光边框提升质感
              width: 0.5,
            ),
          ),
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
                        height: 1,
                        thickness: 0.5,
                        indent: 74, // 优化对齐：分割线与文字左侧对齐，而非贯穿图标
                        endIndent: 20,
                        color: cs.outlineVariant.withOpacity(0.5),
                      ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
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
            width: 40,
            height: 40, // 微调至 40，让图标容器更加饱满
            decoration: BoxDecoration(
              color: cs.primaryContainer.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: cs.onPrimaryContainer),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
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
                  maxLines: 1, // 防止过长溢出破坏布局
                  overflow: TextOverflow.ellipsis,
                ),
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
    final vm = context.watch<HomeViewModel>();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'NekoSU',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
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
                  // TODO: install sheet
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('服务运行正常'),
                      behavior: SnackBarBehavior.floating, // 悬浮 SnackBar 更现代
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
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
