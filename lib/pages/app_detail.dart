import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nekosu/app_icon.dart';
import 'package:nekosu/apps.dart';
import 'package:nekosu/card_group.dart';
import 'package:nekosu/ffi.dart';
import 'package:nekosu/l10n/app_localizations.dart';

class AppDetailPage extends StatefulWidget {
  const AppDetailPage({super.key, required this.app, this.config});

  final AppInfo app;
  final AppConfig? config;

  @override
  State<AppDetailPage> createState() => _AppDetailPageState();
}

class _AppDetailPageState extends State<AppDetailPage> {
  late bool _allowed;
  late int _rootUid;
  late Set<int> _caps;
  late String _domain;
  late NksuNamespace _namespace;
  bool _saveErrorShown = false;

  @override
  void initState() {
    super.initState();
    final config = widget.config;
    _allowed = config?.allowed ?? false;
    _rootUid = config?.rootUid ?? 0;
    _caps = config?.caps.toSet() ?? {...defaultCaps};
    _domain = config?.selinuxDomain ?? defaultSelinuxDomain;
    _namespace = config?.namespace ?? NksuNamespace.inherited;
  }

  void _persist() {
    final success = _allowed
        ? NcoreFfi.setProfile(
            uid: widget.app.uid,
            rootUid: _rootUid,
            caps: _caps.fold(0, (bits, cap) => bits | (1 << cap)),
            domain: _domain,
            namespace: _namespace.value,
          )
        : NcoreFfi.deleteProfile(widget.app.uid);

    if (!mounted) return;
    if (success) {
      _saveErrorShown = false;
      return;
    }
    if (_saveErrorShown) return;
    _saveErrorShown = true;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.profileSaveFailed)));
  }

  void _toggleAllowed(bool value) {
    setState(() {
      _allowed = value;
      if (value) {
        if (_caps.isEmpty) _caps = {...defaultCaps};
        if (_domain.trim().isEmpty) _domain = defaultSelinuxDomain;
      } else {
        _caps = <int>{};
        _domain = defaultSelinuxDomain;
        _namespace = NksuNamespace.inherited;
      }
    });
    _persist();
  }

  Future<void> _editRootUid() async {
    final value = await showDialog<int>(
      context: context,
      builder: (context) => _RootUidDialog(current: _rootUid),
    );
    if (value == null || !mounted) return;
    setState(() => _rootUid = value);
    _persist();
  }

  Future<void> _editDomain() async {
    final value = await showDialog<String>(
      context: context,
      builder: (context) => _DomainDialog(current: _domain),
    );
    if (value == null || !mounted) return;
    final domain = value.trim().isEmpty ? defaultSelinuxDomain : value.trim();
    setState(() => _domain = domain);
    _persist();
  }

  Future<void> _editNamespace() async {
    final l10n = AppLocalizations.of(context)!;
    final value = await showModalBottomSheet<NksuNamespace>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                child: Text(
                  l10n.mountNamespace,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              for (final namespace in NksuNamespace.values)
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  leading: Icon(
                    namespace == _namespace
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    color: namespace == _namespace
                        ? scheme.primary
                        : scheme.onSurfaceVariant,
                  ),
                  title: Text(_namespaceLabel(l10n, namespace)),
                  subtitle: Text(_namespaceDescription(l10n, namespace)),
                  onTap: () => Navigator.of(context).pop(namespace),
                ),
            ],
          ),
        );
      },
    );
    if (value == null || !mounted) return;
    setState(() => _namespace = value);
    _persist();
  }

  Future<void> _editCaps() async {
    final value = await showModalBottomSheet<Set<int>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => _CapsSheet(initial: _caps),
    );
    if (value == null || !mounted) return;
    setState(() => _caps = value);
    _persist();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: scheme.surfaceContainer,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: scheme.surfaceContainer,
            surfaceTintColor: Colors.transparent,
            scrolledUnderElevation: 0,
            elevation: 0,
            title: Text(l10n.appProfileTitle),
            leading: const BackButton(),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              32 + MediaQuery.viewPaddingOf(context).bottom,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _AppIdentityHeader(app: widget.app),
                  const SizedBox(height: 24),
                  _SectionTitle(text: l10n.accessPermissions),
                  const SizedBox(height: 8),
                  _AuthorizationCard(
                    allowed: _allowed,
                    onChanged: _toggleAllowed,
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: _allowed
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 24),
                              _SectionTitle(text: l10n.rootConfiguration),
                              const SizedBox(height: 8),
                              _ConfigItem(
                                index: 0,
                                total: 4,
                                icon: Icons.badge_outlined,
                                title: l10n.rootUid,
                                summary: '$_rootUid',
                                onTap: _editRootUid,
                              ),
                              const SizedBox(height: 2),
                              _ConfigItem(
                                index: 1,
                                total: 4,
                                icon: Icons.tune_rounded,
                                title: l10n.capabilities,
                                summary: l10n.capabilitiesSelected(
                                  _caps.length,
                                  linuxCaps.length,
                                ),
                                onTap: _editCaps,
                              ),
                              const SizedBox(height: 2),
                              _ConfigItem(
                                index: 2,
                                total: 4,
                                icon: Icons.shield_outlined,
                                title: l10n.selinuxDomain,
                                summary: _domain,
                                onTap: _editDomain,
                              ),
                              const SizedBox(height: 2),
                              _ConfigItem(
                                index: 3,
                                total: 4,
                                icon: Icons.layers_outlined,
                                title: l10n.mountNamespace,
                                summary: _namespaceLabel(l10n, _namespace),
                                onTap: _editNamespace,
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppIdentityHeader extends StatelessWidget {
  const _AppIdentityHeader({required this.app});

  final AppInfo app;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: AppIcon(packageName: app.packageName, size: 60),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                app.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.headlineSmall,
              ),
              const SizedBox(height: 2),
              Text(
                app.packageName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    l10n.uidLabel(app.uid),
                    style: textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  if (app.isSystem) ...[
                    const SizedBox(width: 8),
                    _ModeLabel(
                      label: l10n.tagSystem,
                      foreground: scheme.onTertiaryContainer,
                      background: scheme.tertiaryContainer,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AuthorizationCard extends StatelessWidget {
  const _AuthorizationCard({required this.allowed, required this.onChanged});

  final bool allowed;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return Material(
      color: scheme.surfaceBright,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onChanged(!allowed),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: animation,
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: Icon(
                    allowed ? Icons.lock_open_rounded : Icons.lock_rounded,
                    key: ValueKey(allowed),
                    color: allowed ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.allowRootAccess, style: textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      l10n.allowRootAccessSummary,
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Switch(value: allowed, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfigItem extends StatelessWidget {
  const _ConfigItem({
    required this.index,
    required this.total,
    required this.icon,
    required this.title,
    required this.summary,
    required this.onTap,
  });

  final int index;
  final int total;
  final IconData icon;
  final String title;
  final String summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ClipRRect(
      borderRadius: groupShape(index, total),
      child: Material(
        color: scheme.surfaceBright,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: scheme.onSurfaceVariant),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: textTheme.bodyLarge),
                      const SizedBox(height: 2),
                      Text(
                        summary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.keyboard_arrow_right_rounded,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CapsSheet extends StatefulWidget {
  const _CapsSheet({required this.initial});

  final Set<int> initial;

  @override
  State<_CapsSheet> createState() => _CapsSheetState();
}

class _RootUidDialog extends StatefulWidget {
  const _RootUidDialog({required this.current});

  final int current;

  @override
  State<_RootUidDialog> createState() => _RootUidDialogState();
}

class _RootUidDialogState extends State<_RootUidDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.current}');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(int.tryParse(_controller.text.trim()) ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.rootUid),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(10),
        ],
        decoration: InputDecoration(
          labelText: l10n.rootUidInput,
          helperText: l10n.rootUidDescription,
          helperMaxLines: 2,
          border: const OutlineInputBorder(),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.dialogCancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.dialogConfirm)),
      ],
    );
  }
}

class _DomainDialog extends StatefulWidget {
  const _DomainDialog({required this.current});

  final String current;

  @override
  State<_DomainDialog> createState() => _DomainDialogState();
}

class _DomainDialogState extends State<_DomainDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.current);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_controller.text);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.selinuxDomain),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.text,
        decoration: InputDecoration(
          labelText: l10n.selinuxDomainInput,
          helperText: l10n.selinuxDomainDescription,
          helperMaxLines: 2,
          hintText: defaultSelinuxDomain,
          border: const OutlineInputBorder(),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.dialogCancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.dialogConfirm)),
      ],
    );
  }
}

class _CapsSheetState extends State<_CapsSheet> {
  late Set<int> _selected;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selected = widget.initial.toSet();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final query = _query.trim().toLowerCase();
    final filtered = linuxCaps.where((cap) {
      if (query.isEmpty) return true;
      final description = _capDescription(l10n, cap.value).toLowerCase();
      return cap.name.toLowerCase().contains(query) ||
          description.contains(query) ||
          cap.value.toString() == query;
    }).toList();

    return FractionallySizedBox(
      heightFactor: 0.9,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.capabilities, style: textTheme.headlineSmall),
                      Text(
                        l10n.capabilitiesSelected(
                          _selected.length,
                          linuxCaps.length,
                        ),
                        style: textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: l10n.capsSearchHint,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                filled: true,
                fillColor: scheme.surfaceContainerHigh,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: () => setState(
                      () =>
                          _selected = linuxCaps.map((cap) => cap.value).toSet(),
                    ),
                    child: Text(l10n.dialogSelectAll),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: () =>
                        setState(() => _selected = {...defaultCaps}),
                    child: Text(l10n.dialogDefault),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: () => setState(() => _selected = <int>{}),
                    child: Text(l10n.dialogClear),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final cap = filtered[index];
                final selected = _selected.contains(cap.value);
                return CheckboxListTile(
                  value: selected,
                  onChanged: (value) {
                    setState(() {
                      if (value ?? false) {
                        _selected.add(cap.value);
                      } else {
                        _selected.remove(cap.value);
                      }
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text('CAP_${cap.name}', style: textTheme.bodyMedium),
                  subtitle: Text(
                    _capDescription(l10n, cap.value),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelSmall,
                  ),
                  secondary: Text(
                    '${cap.value}',
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () =>
                    Navigator.of(context).pop(Set<int>.from(_selected)),
                child: Text(l10n.dialogDone),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall
            ?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}

class _ModeLabel extends StatelessWidget {
  const _ModeLabel({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: foreground, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

String _namespaceLabel(AppLocalizations l10n, NksuNamespace namespace) {
  return switch (namespace) {
    NksuNamespace.inherited => l10n.namespaceInheritedLabel,
    NksuNamespace.individual => l10n.namespaceIndividualLabel,
    NksuNamespace.global => l10n.namespaceGlobalLabel,
  };
}

String _namespaceDescription(AppLocalizations l10n, NksuNamespace namespace) {
  return switch (namespace) {
    NksuNamespace.inherited => l10n.namespaceInheritedDescription,
    NksuNamespace.individual => l10n.namespaceIndividualDescription,
    NksuNamespace.global => l10n.namespaceGlobalDescription,
  };
}

String _capDescription(AppLocalizations l10n, int value) {
  final descriptions = [
    l10n.capDescChown,
    l10n.capDescDacOverride,
    l10n.capDescDacReadSearch,
    l10n.capDescFowner,
    l10n.capDescFsetid,
    l10n.capDescKill,
    l10n.capDescSetgid,
    l10n.capDescSetuid,
    l10n.capDescSetpcap,
    l10n.capDescLinuxImmutable,
    l10n.capDescNetBindService,
    l10n.capDescNetBroadcast,
    l10n.capDescNetAdmin,
    l10n.capDescNetRaw,
    l10n.capDescIpcLock,
    l10n.capDescIpcOwner,
    l10n.capDescSysModule,
    l10n.capDescSysRawio,
    l10n.capDescSysChroot,
    l10n.capDescSysPtrace,
    l10n.capDescSysPacct,
    l10n.capDescSysAdmin,
    l10n.capDescSysBoot,
    l10n.capDescSysNice,
    l10n.capDescSysResource,
    l10n.capDescSysTime,
    l10n.capDescSysTtyConfig,
    l10n.capDescMknod,
    l10n.capDescLease,
    l10n.capDescAuditWrite,
    l10n.capDescAuditControl,
    l10n.capDescSetfcap,
    l10n.capDescMacOverride,
    l10n.capDescMacAdmin,
    l10n.capDescSyslog,
    l10n.capDescWakeAlarm,
    l10n.capDescBlockSuspend,
    l10n.capDescAuditRead,
    l10n.capDescPerfmon,
    l10n.capDescBpf,
    l10n.capDescCheckpointRestore,
  ];
  return value >= 0 && value < descriptions.length ? descriptions[value] : '';
}
