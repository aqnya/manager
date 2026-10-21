import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:nekosu/card_group.dart';
import 'package:nekosu/ffi.dart';
import 'package:nekosu/haze_app_bar.dart';
import 'package:nekosu/layout_insets.dart';
import 'package:nekosu/l10n/app_localizations.dart';

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
    final navBarClearance = floatingNavBarClearance(context);

    return Scaffold(
      backgroundColor: scheme.surfaceContainer,
      body: CustomScrollView(
        slivers: [
          HazeSliverAppBar(title: Text(l10n.appTitle)),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, navBarClearance),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StatusCard(
                    status: installStatus,
                    isGki: isGki,
                    managerVersion: managerVersion,
                  ),
                  const SizedBox(height: 13),
                  _SectionLabel(text: l10n.deviceAndKernel),
                  const SizedBox(height: 13),
                  const _DeviceInfoList(),
                  const SizedBox(height: 13),
                  _SectionLabel(text: l10n.about),
                  const SizedBox(height: 13),
                  const _AboutItem(),
                ],
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
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    final isWorking = status == InstallStatus.installed;
    final isUpdate =
        status == InstallStatus.needUpdate ||
        status == InstallStatus.needReboot;

    final containerColor = isWorking
        ? scheme.secondaryContainer
        : isUpdate
        ? scheme.tertiaryContainer
        : scheme.errorContainer;
    final contentColor = isWorking
        ? scheme.onSecondaryContainer
        : isUpdate
        ? scheme.onTertiaryContainer
        : scheme.onErrorContainer;
    final icon = isWorking
        ? Icons.check_circle_rounded
        : isUpdate
        ? Icons.system_update_rounded
        : Icons.warning_rounded;
    final title = isWorking
        ? l10n.running
        : isUpdate
        ? l10n.needUpdate
        : l10n.notInstalled;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(28),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(icon, color: contentColor, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: textTheme.titleMedium?.copyWith(
                          color: contentColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isWorking ? managerVersion : l10n.clickToInstall,
                        style: textTheme.bodyMedium?.copyWith(
                          color: contentColor.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                _ModeLabel(
                  label: isGki ? 'GKI' : 'LKM',
                  color: contentColor,
                  containerColor: contentColor.withValues(alpha: 0.16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeLabel extends StatelessWidget {
  const _ModeLabel({
    required this.label,
    required this.color,
    required this.containerColor,
  });

  final String label;
  final Color color;
  final Color containerColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        label,
        maxLines: 1,
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: color, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall
            ?.copyWith(color: Theme.of(context).colorScheme.primary),
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
    final l10n = AppLocalizations.of(context)!;
    final entries = [
      _InfoEntry(label: l10n.kernelVersion, value: _kernelVersion),
      _InfoEntry(label: l10n.androidVersion, value: _androidVersion),
      _InfoEntry(label: l10n.deviceModel, value: _model),
      _InfoEntry(label: l10n.fingerprint, value: _fingerprint),
    ];

    return _SegmentedList(entries: entries);
  }
}

class _InfoEntry {
  const _InfoEntry({required this.label, required this.value});

  final String label;
  final String value;
}

class _SegmentedList extends StatelessWidget {
  const _SegmentedList({required this.entries});

  final List<_InfoEntry> entries;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int index = 0; index < entries.length; index++) ...[
          if (index > 0) const SizedBox(height: 2),
          ClipRRect(
            borderRadius: groupShape(index, entries.length),
            child: ColoredBox(
              color: scheme.surfaceBright,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entries[index].label, style: textTheme.bodyLarge),
                    const SizedBox(height: 2),
                    Text(entries[index].value, style: textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _AboutItem extends StatelessWidget {
  const _AboutItem();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return Material(
      color: scheme.surfaceBright,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.aboutCardTitle, style: textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      l10n.aboutCardDescription,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.keyboard_arrow_right_rounded,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
