import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:nekosu/core/ncore_ffi.dart';
import 'package:nekosu/features/about/about_page.dart';
import 'package:nekosu/l10n/app_localizations.dart';
import 'package:nekosu/shared/layout_insets.dart';

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
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final navBarClearance = appNavBarClearance(context);
    final horizontalPadding = MediaQuery.sizeOf(context).width >= 600
        ? 24.0
        : 16.0;

    return Scaffold(
      backgroundColor: scheme.surfaceContainer,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.medium(
            title: Text(l10n.appTitle),
            backgroundColor: scheme.surfaceContainer,
            surfaceTintColor: Colors.transparent,
            scrolledUnderElevation: 0,
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              8,
              horizontalPadding,
              navBarClearance,
            ),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _StatusCard(
                        status: installStatus,
                        isGki: isGki,
                        managerVersion: managerVersion,
                      ),
                      const SizedBox(height: 24),
                      _SectionHeader(text: l10n.deviceAndKernel),
                      const SizedBox(height: 8),
                      const _DeviceInfoList(),
                      const SizedBox(height: 24),
                      _SectionHeader(text: l10n.about),
                      const SizedBox(height: 8),
                      const _AboutItem(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
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

    final isUpdate =
        status == InstallStatus.needUpdate ||
        status == InstallStatus.needReboot;
    final isKernelAvailable = status == InstallStatus.installed || isUpdate;
    final (containerColor, contentColor, icon) = switch (status) {
      InstallStatus.installed => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
        Icons.verified_rounded,
      ),
      InstallStatus.needUpdate || InstallStatus.needReboot => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
        Icons.system_update_rounded,
      ),
      _ => (
        scheme.errorContainer,
        scheme.onErrorContainer,
        Icons.error_outline_rounded,
      ),
    };
    final title = switch (status) {
      InstallStatus.installed => l10n.running,
      InstallStatus.needUpdate || InstallStatus.needReboot => l10n.needUpdate,
      _ => l10n.notInstalled,
    };

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: containerColor,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: contentColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 28, color: contentColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: contentColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.aboutTagline,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: contentColor.withValues(alpha: 0.78),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isKernelAvailable) ...[
                  const SizedBox(width: 12),
                  _ModeBadge(label: isGki ? 'GKI' : 'LKM', color: contentColor),
                ],
              ],
            ),
            const SizedBox(height: 24),
            Divider(
              height: 1,
              thickness: 1,
              color: contentColor.withValues(alpha: 0.16),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.managerVersion,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: contentColor.withValues(alpha: 0.72),
                    ),
                  ),
                ),
                Text(
                  'v$managerVersion',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: contentColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeBadge extends StatelessWidget {
  const _ModeBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.28)),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        maxLines: 1,
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: color, letterSpacing: 0.6),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          text.toUpperCase(),
          style: theme.textTheme.labelLarge?.copyWith(
            color: scheme.primary,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }
}

class _DeviceInfoList extends StatefulWidget {
  const _DeviceInfoList();

  @override
  State<_DeviceInfoList> createState() => _DeviceInfoListState();
}

class _DeviceInfoListState extends State<_DeviceInfoList> {
  String _kernelVersion = '...';
  String _androidVersion = '...';
  String _model = '...';
  String _fingerprint = '...';

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

  Future<String> _loadKernelVersion() async {
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
    return 'Unknown';
  }

  void _setFallback(String kernelVersion) {
    if (!mounted) return;
    setState(() {
      _kernelVersion = kernelVersion;
      _androidVersion = Platform.operatingSystem;
      _model = 'Unknown';
      _fingerprint = 'Unknown';
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
        value: _kernelVersion,
      ),
      _InfoEntry(
        icon: Icons.android_rounded,
        label: l10n.androidVersion,
        value: _androidVersion,
      ),
      _InfoEntry(
        icon: Icons.smartphone_rounded,
        label: l10n.deviceModel,
        value: _model,
      ),
      _InfoEntry(
        icon: Icons.fingerprint_rounded,
        label: l10n.fingerprint,
        value: _fingerprint,
        monospace: true,
      ),
    ];

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: scheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          for (var index = 0; index < entries.length; index++) ...[
            _DeviceInfoRow(entry: entries[index]),
            if (index < entries.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                indent: 72,
                endIndent: 16,
                color: scheme.outlineVariant.withValues(alpha: 0.4),
              ),
          ],
        ],
      ),
    );
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
        : theme.textTheme.bodyLarge?.copyWith(color: scheme.onSurface);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      minVerticalPadding: 8,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(entry.icon, size: 20, color: scheme.onSurfaceVariant),
      ),
      title: Text(
        entry.label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          entry.value,
          maxLines: entry.monospace ? 3 : 2,
          overflow: TextOverflow.ellipsis,
          style: valueStyle,
        ),
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

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: scheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: ListTile(
        onTap: () => Navigator.of(context).push<void>(
          MaterialPageRoute(builder: (context) => const AboutPage()),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minVerticalPadding: 10,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: scheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          l10n.aboutCardTitle,
          style: theme.textTheme.titleMedium?.copyWith(color: scheme.onSurface),
        ),
        subtitle: Text(
          l10n.aboutCardDescription,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
