import 'package:flutter/material.dart';
import "info.dart";

class RootHomePage extends StatefulWidget {
  const RootHomePage({super.key});

  @override
  State<RootHomePage> createState() => _RootHomePageState();
}

class _RootHomePageState extends State<RootHomePage> {
  String _kernelVersion = 'loading...';
  String _selinuxStatus = 'loading...';

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    final kernel_version = await getKernelRelease();
    final selinux_status = await getSELinuxStatus();
    if (mounted)
      setState(() {
        _kernelVersion = kernel_version;
        _selinuxStatus = selinux_status;
      });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          scrolledUnderElevation: 0,
          backgroundColor: Colors.transparent,
          title: const Text(
            "NekoSU",
            style: TextStyle(fontWeight: FontWeight.normal, fontSize: 23.0),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
            children: [
              _buildHeroBanner(context),
              const SizedBox(height: 12),
              _buildStatsRow(context),
              const SizedBox(height: 12),
              _buildSystemInfo(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroBanner(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, Color.lerp(primary, Colors.black, 0.25)!],
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          Positioned(
            right: -24,
            bottom: -24,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.07),
              ),
            ),
          ),
          Positioned(
            right: 24,
            bottom: -40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.07),
              ),
            ),
          ),
          Positioned(
            right: 20,
            top: 20,
            child: Icon(
              Icons.pets_rounded,
              size: 80,
              color: Colors.white.withOpacity(0.12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Welcome to',
                  style: TextStyle(
                    color: onPrimary.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'NekoSU',
                  style: TextStyle(
                    color: onPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    _kernelVersion,
                    style: TextStyle(
                      color: onPrimary,
                      fontSize: 12,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            value: '12',
            label: '授权应用',
            icon: Icons.shield_rounded,
            iconColor: colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            value: 'FMAC',
            label: '安全模块 (Active)',
            icon: Icons.security_rounded,
            iconColor: Colors.green,
            valueColor: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String value,
    required String label,
    required IconData icon,
    required Color iconColor,
    Color? valueColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -8,
            bottom: -8,
            child: Icon(icon, size: 64, color: iconColor.withOpacity(0.12)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: valueColor ?? colorScheme.onSurface,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSystemInfo(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _buildInfoRow(
            context,
            label: '内核版本',
            value: _kernelVersion,
            isFirst: true,
          ),
          _buildInfoRow(context, label: 'SELinux', value: 'Enforcing'),
          _buildInfoRow(
            context,
            label: '版本',
            value: 'FMAC v1.0.2',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required String label,
    required String value,
    Color? valueColor,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        if (!isFirst) ...[
          Divider(
            color: colorScheme.outlineVariant.withOpacity(0.5),
            height: 1,
          ),
          const SizedBox(height: 14),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: TextStyle(
                  color: valueColor ?? colorScheme.onSurface,
                  fontSize: 13,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        if (!isLast) const SizedBox(height: 14),
      ],
    );
  }
}
