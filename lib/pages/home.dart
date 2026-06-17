import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:nekosu/l10n/app_localizations.dart';
import 'package:nekosu/ffi.dart';

enum InstallStatus { installed, notInstalled }

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
  final installStatus = NCore.isInstalled()
        ? InstallStatus.installed
        : InstallStatus.notInstalled;
    return _HomeScreenContent(
      installStatus: installStatus,
      suCount: 0,
      ruleCount: 0,
      showRules: false,
    );
  }
}

class RebootListPopup extends StatelessWidget {
  const RebootListPopup({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {},
      itemBuilder: (context) => [
        PopupMenuItem(value: 'reboot', child: Text(l10n.reboot)),
        PopupMenuItem(value: 'recovery', child: Text(l10n.rebootToRecovery)),
        PopupMenuItem(value: 'bootloader', child: Text(l10n.rebootToBootloader)),
      ],
    );
  }
}

class _HomeScreenContent extends StatelessWidget {
  const _HomeScreenContent({
    required this.installStatus,
    required this.suCount,
    required this.ruleCount,
    required this.showRules,
    this.onNavigateToApps,
    this.onNavigateToRules,
    this.onInstallClick,
  });

  final InstallStatus installStatus;
  final int suCount;
  final int ruleCount;
  final bool showRules;
  final VoidCallback? onNavigateToApps;
  final VoidCallback? onNavigateToRules;
  final VoidCallback? onInstallClick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.medium(
            title: Text(
              l10n.appTitle,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            actions: const [RebootListPopup()],
            backgroundColor: Theme.of(context).colorScheme.surface,
            surfaceTintColor: Colors.transparent,
            scrolledUnderElevation: 0,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _StatusCard(
                  status: installStatus,
                  onClick: onInstallClick ?? () {},
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: l10n.superuser,
                        value: suCount.toString(),
                        icon: Icons.numbers,
                        onClick: onNavigateToApps ?? () {},
                      ),
                    ),
                    if (showRules) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: l10n.fmacRules,
                          value: ruleCount.toString(),
                          icon: Icons.rule,
                          onClick: onNavigateToRules ?? () {},
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                const _DeviceInfoCard(),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── StatusCard ────────────────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.status, required this.onClick});

  final InstallStatus status;
  final VoidCallback onClick;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.surface.computeLuminance() < 0.5;
    final l10n = AppLocalizations.of(context)!;

    final containerColor = switch (status) {
      InstallStatus.installed => scheme.primaryContainer,
      InstallStatus.notInstalled =>
        isDark ? scheme.errorContainer : scheme.error,
    };
    final contentColor = switch (status) {
      InstallStatus.installed => scheme.onPrimaryContainer,
      InstallStatus.notInstalled =>
        isDark ? scheme.onErrorContainer : scheme.onError,
    };
    final icon = switch (status) {
      InstallStatus.installed => Icons.check_circle,
      InstallStatus.notInstalled => Icons.system_update,
    };
    final title = switch (status) {
      InstallStatus.installed => l10n.installed,
      InstallStatus.notInstalled => l10n.notInstalled,
    };
    final sub = switch (status) {
      InstallStatus.installed => l10n.running,
      InstallStatus.notInstalled => l10n.clickToInstall,
    };

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Material(
        color: containerColor.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          onTap: onClick,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                _GlowCircle(
                  size: 50,
                  color: contentColor,
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
                      const SizedBox(height: 3),
                      Text(
                        sub,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: contentColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                _GlowCircle(
                  size: 30,
                  color: contentColor,
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: contentColor.withValues(alpha: 0.6),
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

// ── StatCard ──────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.onClick,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onClick;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      color: scheme.surfaceContainer,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onClick,
        child: SizedBox(
          width: double.infinity,
          child: Stack(
            children: [
              Positioned(
                right: 18,
                bottom: 12,
                child: Icon(
                  icon,
                  size: 58,
                  color: scheme.primary.withValues(alpha: 0.35),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: scheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── DeviceInfoCard ────────────────────────────────────────────────────────────

class _DeviceInfoCard extends StatelessWidget {
  const _DeviceInfoCard();

  static String _kernelVersion() {
    try {
      return Platform.operatingSystemVersion;
    } catch (_) {
      return 'Linux';
    }
  }

  static String _androidVersion() {
    try {
      return Platform.operatingSystem;
    } catch (_) {
      return 'Android';
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final items = [
      (Icons.memory, l10n.kernelVersion, _kernelVersion()),
      (Icons.android, l10n.androidVersion, _androidVersion()),
      (Icons.phone_android, l10n.deviceModel, 'Device'),
      (Icons.settings, l10n.managerVersion, '1.0.0'),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    scheme.primary.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            elevation: 0,
            color: scheme.surfaceContainer,
            child: Column(
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  _DeviceInfoItem(
                    icon: items[i].$1,
                    title: items[i].$2,
                    value: items[i].$3,
                  ),
                  if (i < items.length - 1)
                    Divider(
                      indent: 20,
                      endIndent: 20,
                      thickness: 0.5,
                      color: scheme.outlineVariant,
                      height: 0,
                    ),
                ],
              ],
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
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: scheme.onPrimaryContainer, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface,
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

// ── GlowCircle ────────────────────────────────────────────────────────────────

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({
    required this.size,
    required this.color,
    required this.child,
  });

  final double size;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GlowPainter(color: color),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          shape: BoxShape.circle,
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _GlowPainter extends CustomPainter {
  const _GlowPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 1.8;
    final paint = Paint()
      ..shader =
          RadialGradient(
            colors: [color.withValues(alpha: 0.25), Colors.transparent],
          ).createShader(
            Rect.fromCircle(center: size.center(Offset.zero), radius: r),
          );
    canvas.drawCircle(size.center(Offset.zero), r, paint);
  }

  @override
  bool shouldRepaint(_GlowPainter old) => old.color != color;
}
