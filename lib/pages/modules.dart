import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nekosu/app_popup_menu.dart';
import 'package:nekosu/l10n/app_localizations.dart';
import 'package:nekosu/layout_insets.dart';
import 'package:nekosu/modules.dart';
import 'package:nekosu/pages/webui.dart';

class ModulesPage extends StatefulWidget {
  const ModulesPage({super.key});

  @override
  State<ModulesPage> createState() => _ModulesPageState();
}

class _ModulesPageState extends State<ModulesPage> {
  List<ModuleInfo> _modules = const [];
  final Set<String> _busyModules = {};

  bool _loading = true;
  String? _loadError;

  bool _logVisible = false;
  bool _logRunning = false;
  String? _logType;
  String _logTitle = '';
  String _logText = '';
  int? _logCode;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _modules.isEmpty;
      _loadError = null;
    });
    final result = await ModuleBridge.list();
    if (!mounted) return;
    setState(() {
      _modules = result.modules;
      _loading = false;
      _loadError = result.ok ? null : result.output.trim();
    });
  }

  Future<void> _installModule() async {
    if (_logRunning) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _logVisible = true;
      _logRunning = true;
      _logType = 'install';
      _logTitle = l10n.modulesInstallRunning;
      _logText = '';
      _logCode = null;
    });
    try {
      final path = await ModuleBridge.pickZip();
      if (!mounted) return;
      if (path == null) {
        _closeLog();
        return;
      }
      final result = await ModuleBridge.install(path);
      _finishCommandResult(result);
    } on PlatformException catch (error) {
      _finishLocalLog(error.message ?? error.code);
    } on MissingPluginException {
      _finishLocalLog('Module bridge is unavailable');
    } catch (error) {
      _finishLocalLog(error.toString());
    }
  }

  Future<void> _runAction(ModuleInfo module) async {
    if (_busyModules.contains(module.id) || _logRunning) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _busyModules.add(module.id);
      _logVisible = true;
      _logRunning = true;
      _logType = 'action';
      _logTitle = '${l10n.modulesActionRunning} · ${module.title}';
      _logText = '';
      _logCode = null;
    });
    final result = await ModuleBridge.action(module.id);
    _finishCommandResult(result, moduleId: module.id);
  }

  void _finishCommandResult(ModuleCommandResult result, {String? moduleId}) {
    if (!mounted) return;
    setState(() {
      if (moduleId != null) _busyModules.remove(moduleId);
      _logRunning = false;
      _logCode = result.code;
      final output = result.output.trim();
      if (output.isNotEmpty) {
        _logText = '${_logText.trim()}\n$output'.trim();
        const maxLogLength = 256 * 1024;
        if (_logText.length > maxLogLength) {
          _logText = _logText.substring(_logText.length - maxLogLength);
        }
      }
    });
    if (result.ok) unawaited(_load());
  }

  void _finishLocalLog(String message) {
    if (!mounted) return;
    setState(() {
      _logRunning = false;
      _logCode = -1;
      if (message.trim().isNotEmpty) _logText += '${message.trim()}\n';
    });
  }

  void _closeLog() {
    setState(() {
      _logVisible = false;
      _logRunning = false;
      _logType = null;
      _logTitle = '';
      _logText = '';
      _logCode = null;
    });
  }

  Future<bool> _runModuleOperation(ModuleInfo module, String operation) async {
    if (_busyModules.contains(module.id)) return false;
    setState(() => _busyModules.add(module.id));
    final result = await ModuleBridge.run(operation: operation, id: module.id);
    if (!mounted) return result.ok;
    setState(() => _busyModules.remove(module.id));
    if (!result.ok) {
      _showMessage(
        result.output.trim().isEmpty
            ? 'Operation failed'
            : result.output.trim(),
      );
      return false;
    } else {
      await _load();
      return true;
    }
  }

  Future<void> _setEnabled(ModuleInfo module, bool enabled) async {
    await _runModuleOperation(module, enabled ? 'enable' : 'disable');
  }

  Future<void> _removeModule(ModuleInfo module) async {
    final succeeded = await _runModuleOperation(module, 'remove');
    if (mounted && succeeded) {
      final l10n = AppLocalizations.of(context)!;
      _showMessage(l10n.modulesRemoveHint);
    }
  }

  Future<void> _undoRemove(ModuleInfo module) async {
    await _runModuleOperation(module, 'undoRemove');
  }

  Future<void> _uninstallModule(ModuleInfo module) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.modulesUninstall),
        content: Text(l10n.modulesUninstallConfirm(module.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.dialogCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.dialogConfirm),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _runModuleOperation(module, 'uninstall');
    }
  }

  Future<void> _openWebUi(ModuleInfo module) async {
    final result = await ModuleBridge.prepareWebUi(module.id);
    if (!mounted) return;
    if (!result.ok) {
      _showMessage(
        result.output.trim().isEmpty
            ? 'Unable to open WebUI'
            : result.output.trim(),
      );
      return;
    }
    final entryPath = result.output.trim();
    if (entryPath.isEmpty) {
      _showMessage('Unable to open WebUI');
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => WebUiPage(entryPath: entryPath, module: module),
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _logHeader(AppLocalizations l10n) {
    if (_logRunning) {
      return _logType == 'action' ? _logTitle : l10n.modulesInstallRunning;
    }
    final succeeded = _logCode == 0;
    if (_logType == 'action') {
      return succeeded ? l10n.modulesActionDone : l10n.modulesActionFailed;
    }
    return succeeded ? l10n.modulesInstallDone : l10n.modulesInstallFailed;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final navBarClearance = floatingNavBarClearance(context);
    final scheme = Theme.of(context).colorScheme;

    if (_logVisible) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && !_logRunning) _closeLog();
        },
        child: Scaffold(
          backgroundColor: scheme.surfaceContainer,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: scheme.surfaceContainer,
                surfaceTintColor: Colors.transparent,
                scrolledUnderElevation: 0,
                elevation: 0,
                title: Text(_logHeader(l10n)),
                leading: _logRunning
                    ? null
                    : IconButton(
                        onPressed: _closeLog,
                        icon: const Icon(Icons.close_rounded),
                        tooltip: l10n.modulesClose,
                      ),
              ),
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, navBarClearance),
                  child: _ModuleLogPanel(
                    text: _logText.trim(),
                    waiting: l10n.modulesWaiting,
                    running: _logRunning,
                    succeeded: _logCode == 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: scheme.surfaceContainer,
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: navBarClearance),
        child: FloatingActionButton(
          onPressed: _installModule,
          tooltip: l10n.modulesInstall,
          child: const Icon(Icons.add_rounded),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: RefreshIndicator(
        color: scheme.primary,
        backgroundColor: scheme.surfaceBright,
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: scheme.surfaceContainer,
              surfaceTintColor: Colors.transparent,
              scrolledUnderElevation: 0,
              elevation: 0,
              title: Text(l10n.modulesLabel),
              actions: [
                IconButton(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: l10n.retry,
                ),
              ],
            ),
            if (_loading)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: EdgeInsets.only(bottom: navBarClearance),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              )
            else if (_modules.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    32,
                    16,
                    32,
                    navBarClearance + 72,
                  ),
                  child: _ModulesEmptyState(
                    failed: _loadError != null,
                    error: _loadError,
                    onRetry: _load,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, navBarClearance + 76),
                sliver: SliverList.builder(
                  itemCount: _modules.length,
                  itemBuilder: (context, index) {
                    final module = _modules[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == _modules.length - 1 ? 0 : 10,
                      ),
                      child: _ModuleCard(
                        module: module,
                        busy: _busyModules.contains(module.id),
                        onToggle: (enabled) => _setEnabled(module, enabled),
                        onAction: () => _runAction(module),
                        onWebUi: () => _openWebUi(module),
                        onRemove: () => _removeModule(module),
                        onUndoRemove: () => _undoRemove(module),
                        onUninstall: () => _uninstallModule(module),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ModuleCard extends StatefulWidget {
  const _ModuleCard({
    required this.module,
    required this.busy,
    required this.onToggle,
    required this.onAction,
    required this.onWebUi,
    required this.onRemove,
    required this.onUndoRemove,
    required this.onUninstall,
  });

  final ModuleInfo module;
  final bool busy;
  final ValueChanged<bool> onToggle;
  final VoidCallback onAction;
  final VoidCallback onWebUi;
  final VoidCallback onRemove;
  final VoidCallback onUndoRemove;
  final VoidCallback onUninstall;

  @override
  State<_ModuleCard> createState() => _ModuleCardState();
}

enum _ModuleMenu { uninstall }

class _ModuleCardState extends State<_ModuleCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final module = widget.module;
    final pendingRemoval = module.remove;
    final textDecoration = pendingRemoval ? TextDecoration.lineThrough : null;
    final actionsVisible = !pendingRemoval && module.enabled;
    final actionEnabled = actionsVisible && !widget.busy;
    final hasDescription = module.description.trim().isNotEmpty;
    final actionCount = [
      module.hasActionScript,
      module.hasWebUi,
    ].where((available) => available).length;
    final showActionText = actionCount <= 1;

    return Material(
      color: scheme.surfaceBright,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: hasDescription
                ? () => setState(() => _expanded = !_expanded)
                : null,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              module.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                                decoration: textDecoration,
                              ),
                            ),
                            if (module.version.isNotEmpty)
                              Text(
                                '${l10n.modulesVersion}: ${module.version}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  decoration: textDecoration,
                                ),
                              ),
                            if (module.author.isNotEmpty)
                              Text(
                                '${l10n.modulesAuthor}: ${module.author}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  decoration: textDecoration,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (widget.busy)
                        const Padding(
                          padding: EdgeInsets.all(10),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      else
                        Switch(
                          value: module.enabled,
                          onChanged: pendingRemoval ? null : widget.onToggle,
                        ),
                    ],
                  ),
                  if (hasDescription) ...[
                    const SizedBox(height: 8),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topCenter,
                      child: Text(
                        module.description,
                        maxLines: _expanded ? null : 3,
                        overflow: _expanded
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          decoration: textDecoration,
                        ),
                      ),
                    ),
                  ],
                  if (module.metamodule || module.update) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (module.metamodule)
                          _ModuleTag(
                            text: l10n.modulesMetamodule,
                            color: scheme.primary,
                          ),
                        if (module.update)
                          _ModuleTag(
                            text: l10n.modulesUpdate,
                            color: scheme.tertiary,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(
              height: 1,
              color: scheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Row(
              children: [
                if (actionsVisible && module.hasActionScript)
                  _ModuleCardButton(
                    onPressed: actionEnabled ? widget.onAction : null,
                    icon: Icons.play_arrow_rounded,
                    label: showActionText ? l10n.modulesAction : null,
                  ),
                if (actionsVisible && module.hasActionScript && module.hasWebUi)
                  const SizedBox(width: 8),
                if (actionsVisible && module.hasWebUi)
                  _ModuleCardButton(
                    onPressed: actionEnabled ? widget.onWebUi : null,
                    icon: Icons.code_rounded,
                    label: showActionText ? l10n.modulesWebUi : null,
                  ),
                const Spacer(),
                _ModuleCardButton(
                  onPressed: widget.busy
                      ? null
                      : pendingRemoval
                      ? widget.onUndoRemove
                      : widget.onRemove,
                  icon: pendingRemoval
                      ? Icons.refresh_rounded
                      : Icons.delete_rounded,
                  label: pendingRemoval
                      ? l10n.modulesUndoRemove
                      : l10n.modulesRemove,
                ),
                const SizedBox(width: 4),
                AppPopupMenu<_ModuleMenu>(
                  enabled: !widget.busy,
                  tooltip: l10n.modulesMore,
                  icon: Icons.more_vert_rounded,
                  onSelected: (_) => widget.onUninstall(),
                  items: [
                    AppPopupMenuItem(
                      value: _ModuleMenu.uninstall,
                      label: l10n.modulesUninstall,
                      destructive: true,
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

class _ModuleCardButton extends StatelessWidget {
  const _ModuleCardButton({
    required this.onPressed,
    required this.icon,
    this.label,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.labelMedium;
    return FilledButton.tonal(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size(52, 36),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: textStyle,
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          if (label != null) ...[const SizedBox(width: 7), Text(label!)],
        ],
      ),
    );
  }
}

class _ModuleTag extends StatelessWidget {
  const _ModuleTag({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

class _ModulesEmptyState extends StatelessWidget {
  const _ModulesEmptyState({
    required this.failed,
    required this.error,
    required this.onRetry,
  });

  final bool failed;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            failed ? Icons.error_outline_rounded : Icons.extension_outlined,
            size: 52,
            color: failed ? scheme.error : scheme.onSurfaceVariant,
          ),
          const SizedBox(height: 14),
          Text(
            failed ? l10n.modulesLoadFailed : l10n.modulesEmpty,
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Text(
            failed && error != null && error!.trim().isNotEmpty
                ? error!.trim()
                : l10n.modulesEmptyHint,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          if (failed)
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.retry),
            ),
        ],
      ),
    );
  }
}

class _ModuleLogPanel extends StatefulWidget {
  const _ModuleLogPanel({
    required this.text,
    required this.waiting,
    required this.running,
    required this.succeeded,
  });

  final String text;
  final String waiting;
  final bool running;
  final bool succeeded;

  @override
  State<_ModuleLogPanel> createState() => _ModuleLogPanelState();
}

class _ModuleLogPanelState extends State<_ModuleLogPanel> {
  final _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant _ModuleLogPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surfaceBright,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                if (widget.running)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    widget.succeeded
                        ? Icons.check_circle_rounded
                        : Icons.error_rounded,
                    size: 20,
                    color: widget.succeeded ? scheme.primary : scheme.error,
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.running
                        ? widget.waiting
                        : widget.text.split('\n').first,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                widget.text.isEmpty ? widget.waiting : widget.text,
                style: textTheme.bodySmall?.copyWith(
                  height: 1.45,
                  color: scheme.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
