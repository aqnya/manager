import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:nekosu/ffi.dart';
import 'package:nekosu/l10n/app_localizations.dart';
import 'package:nekosu/layout_insets.dart';
import 'package:nekosu/pages/about.dart';

enum InstallStatus { installed, needUpdate, needReboot, notInstalled, unknown }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _managerVersion = '1.0.0';

  InstallStatus _installStatus = InstallStatus.unknown;
  bool _isGki = false;

  @override
  void initState() {
    super.initState();
    if (!NcoreFfi.available) return;
    _installStatus = NcoreFfi.isInstalled
        ? InstallStatus.installed
        : InstallStatus.notInstalled;
    _isGki = NcoreFfi.isGki;
  }

  @override
  Widget build(BuildContext context) {
    return _HomeScreenContent(
      installStatus: _installStatus,
      isGki: _isGki,
      managerVersion: _managerVersion,
    );
  }
}

class _HomeScreenContent extends StatelessWidget {
  const _HomeScreenContent({
    required this.installStatus,
    required this.isGki,
    required this.managerVersion,
  });

  final InstallStatus installStatus;
  final bool isGki;
  final String managerVersion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final navBarClearance = appNavBarClearance(context);

    return Scaffold(
      backgroundColor: scheme.surfaceContainer,
      body: Stack(
        children: [
          Positioned(
            top: -128,
            right: -96,
            child: IgnorePointer(
              child: _AmbientGlow(color: scheme.primary, size: 310),
            ),
          ),
          CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                toolbarHeight: 64,
                titleSpacing: 20,
                backgroundColor: scheme.surfaceContainer,
                surfaceTintColor: Colors.transparent,
                scrolledUnderElevation: 0,
                elevation: 0,
                title: Row(
                  children: [
                    const _BrandMark(),
                    const SizedBox(width: 12),
                    Text(
                      l10n.appTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 20,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 6, 20, navBarClearance),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _StatusHero(
                            status: installStatus,
                            isGki: isGki,
                            managerVersion: managerVersion,
                          ),
                          const SizedBox(height: 28),
                          _SectionHeader(text: l10n.deviceAndKernel),
                          const SizedBox(height: 10),
                          const _DeviceInfoList(),
                          const SizedBox(height: 28),
                          _SectionHeader(text: l10n.about),
                          const SizedBox(height: 10),
                          const _AboutItem(),
                          const SizedBox(height: 24),
                          _Footer(l10n: l10n),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary,
            Color.lerp(scheme.primary, scheme.tertiary, 0.38)!,
          ],
        ),
        borderRadius: BorderRadius.circular(13),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.2),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(Icons.pets_rounded, size: 19, color: scheme.onPrimary),
    );
  }
}

class _StatusHero extends StatelessWidget {
  const _StatusHero({
    required this.status,
    required this.isGki,
    required this.managerVersion,
  });

  final InstallStatus status;
  final bool isGki;
  final String managerVersion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final isWorking = status == InstallStatus.installed;
    final isUpdate =
        status == InstallStatus.needUpdate ||
        status == InstallStatus.needReboot;
    final accent = isWorking
        ? scheme.primary
        : isUpdate
        ? scheme.tertiary
        : scheme.error;
    final icon = isWorking
        ? Icons.check_rounded
        : isUpdate
        ? Icons.system_update_rounded
        : Icons.priority_high_rounded;
    final title = isWorking
        ? l10n.running
        : isUpdate
        ? l10n.needUpdate
        : l10n.notInstalled;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.12 : 0.08,
            ),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            top: -76,
            right: -54,
            child: IgnorePointer(child: _AmbientGlow(color: accent, size: 210)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatusOrb(status: status, icon: icon, color: accent),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontSize: 25,
                              height: 1.12,
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            l10n.aboutTagline,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isWorking || isUpdate) ...[
                      const SizedBox(width: 10),
                      _ModePill(label: isGki ? 'GKI' : 'LKM', color: accent),
                    ],
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  height: 1,
                  color: scheme.outlineVariant.withValues(alpha: 0.42),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.managerVersion,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'v$managerVersion',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusOrb extends StatelessWidget {
  const _StatusOrb({
    required this.status,
    required this.icon,
    required this.color,
  });

  final InstallStatus status;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 240),
        transitionBuilder: (child, animation) => ScaleTransition(
          scale: animation,
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: Icon(icon, key: ValueKey(status), size: 26, color: color),
      ),
    );
  }
}

class _ModePill extends StatelessWidget {
  const _ModePill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Text(
        label,
        maxLines: 1,
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: color, letterSpacing: 0.5),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: scheme.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 9),
        Text(
          text,
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _DeviceInfoList extends StatefulWidget {
  const _DeviceInfoList();

  @override
  State<_DeviceInfoList> createState() => _DeviceInfoListState();
}

class _DeviceInfoListState extends State<_DeviceInfoList> {
  String? _kernelVersion;
  String? _androidVersion;
  String? _model;
  String? _fingerprint;

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
  }

  Future<void> _loadDeviceInfo() async {
    final kernelVersion = await _loadKernelVersion();
    if (!Platform.isAndroid) {
      _setFallback(kernelVersion);
      return;
    }

    try {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (!mounted) return;
      setState(() {
        _kernelVersion = kernelVersion;
        _androidVersion = androidInfo.version.release;
        _model = '${androidInfo.manufacturer} ${androidInfo.model}';
        _fingerprint = androidInfo.fingerprint;
      });
    } catch (_) {
      _setFallback(kernelVersion);
    }
  }

  Future<String?> _loadKernelVersion() async {
    if (!Platform.isAndroid) return Platform.operatingSystem;
    final release = NcoreFfi.kernelRelease;
    if (release != null && release.isNotEmpty) return release;
    try {
      final result = await Process.run('/system/bin/uname', const ['-r']);
      if (result.exitCode == 0) {
        final version = result.stdout.toString().trim();
        if (version.isNotEmpty) return version;
      }
    } catch (_) {}
    return null;
  }

  void _setFallback(String? kernelVersion) {
    if (!mounted) return;
    setState(() {
      _kernelVersion = kernelVersion;
      _androidVersion = Platform.operatingSystem;
      _model = null;
      _fingerprint = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final entries = [
      _InfoEntry(
        icon: Icons.memory_rounded,
        label: l10n.kernelVersion,
        value: _displayValue(_kernelVersion, l10n),
      ),
      _InfoEntry(
        icon: Icons.android_rounded,
        label: l10n.androidVersion,
        value: _displayValue(_androidVersion, l10n),
      ),
      _InfoEntry(
        icon: Icons.smartphone_rounded,
        label: l10n.deviceModel,
        value: _displayValue(_model, l10n),
      ),
      _InfoEntry(
        icon: Icons.fingerprint_rounded,
        label: l10n.fingerprint,
        value: _displayValue(_fingerprint, l10n),
        monospace: true,
      ),
    ];

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          for (var index = 0; index < entries.length; index++) ...[
            _DeviceInfoRow(entry: entries[index]),
            if (index < entries.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                indent: 70,
                endIndent: 18,
                color: scheme.outlineVariant.withValues(alpha: 0.3),
              ),
          ],
        ],
      ),
    );
  }

  String _displayValue(String? value, AppLocalizations l10n) {
    if (value == null || value.isEmpty) return l10n.unknownValue;
    return value;
  }
}

class _InfoEntry {
  const _InfoEntry({
    required this.icon,
    required this.label,
    required this.value,
    this.monospace = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool monospace;
}

class _DeviceInfoRow extends StatelessWidget {
  const _DeviceInfoRow({required this.entry});

  final _InfoEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final valueStyle = entry.monospace
        ? theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurface,
            fontFamily: 'monospace',
            height: 1.45,
          )
        : theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurface);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(entry.icon, size: 19, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.value,
                  maxLines: entry.monospace ? 3 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: valueStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutItem extends StatelessWidget {
  const _AboutItem();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push<void>(
          MaterialPageRoute(builder: (context) => const AboutPage()),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 21,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.aboutCardTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.aboutCardDescription,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.65),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${l10n.appTitle} · ${l10n.aboutLicenseShort}',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant.withValues(alpha: 0.72),
          ),
        ),
      ],
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: 0.14), color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}
