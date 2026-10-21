import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nekosu/l10n/app_localizations.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebUiPage extends StatefulWidget {
  const WebUiPage({super.key, required this.entryPath});

  final String entryPath;

  @override
  State<WebUiPage> createState() => _WebUiPageState();
}

class _WebUiPageState extends State<WebUiPage> {
  late final WebViewController _controller;

  bool _loading = true;
  double? _progress;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    await _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await _controller.setBackgroundColor(Colors.transparent);
    await _controller.setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: (_) {
          if (!mounted) return;
          setState(() {
            _loading = true;
            _error = null;
          });
        },
        onPageFinished: (_) {
          if (!mounted) return;
          setState(() {
            _loading = false;
            _progress = null;
          });
        },
        onProgress: (progress) {
          if (!mounted) return;
          setState(() => _progress = progress.clamp(0, 100) / 100);
        },
        onWebResourceError: (error) {
          if (!mounted || error.isForMainFrame == false) return;
          setState(() {
            _loading = false;
            _error = error.description;
          });
        },
      ),
    );
    await _controller.setOnJavaScriptAlertDialog((request) async {
      await _showAlert(request.message);
    });
    await _controller.setOnJavaScriptConfirmDialog(
      (request) => _showConfirm(request.message),
    );
    await _controller.setOnJavaScriptTextInputDialog(
      (request) => _showPrompt(request.message, request.defaultText),
    );
    await _loadEntry();
  }

  Future<void> _loadEntry() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _progress = 0;
      _error = null;
    });
    await _controller.loadFile(widget.entryPath);
  }

  Future<void> _goBack() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _showAlert(String message) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.dialogConfirm),
          ),
        ],
      ),
    );
  }

  Future<bool> _showConfirm(String message) async {
    if (!mounted) return false;
    final l10n = AppLocalizations.of(context)!;
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(l10n.dialogCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(l10n.dialogConfirm),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<String> _showPrompt(String message, String? defaultText) async {
    if (!mounted) return '';
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: defaultText ?? '');
    try {
      return await showDialog<String>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(message),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    onSubmitted: (value) =>
                        Navigator.of(dialogContext).pop(value),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(l10n.dialogCancel),
                ),
                FilledButton(
                  onPressed: () =>
                      Navigator.of(dialogContext).pop(controller.text),
                  child: Text(l10n.dialogConfirm),
                ),
              ],
            ),
          ) ??
          '';
    } finally {
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_goBack());
      },
      child: Scaffold(
        backgroundColor: scheme.surfaceContainer,
        body: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              WebViewWidget(controller: _controller),
              if (_loading && _error == null)
                Align(
                  alignment: Alignment.topCenter,
                  child: LinearProgressIndicator(
                    minHeight: 2,
                    value: _progress,
                    backgroundColor: Colors.transparent,
                    color: scheme.primary,
                  ),
                ),
              if (_loading && _error == null)
                IgnorePointer(
                  child: ColoredBox(
                    color: scheme.surfaceContainer.withValues(alpha: 0.72),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ),
              if (_error != null)
                ColoredBox(
                  color: scheme.surfaceContainer,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.web_asset_off_rounded,
                            size: 48,
                            color: scheme.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.webUiLoadFailed,
                            textAlign: TextAlign.center,
                            style: textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            alignment: WrapAlignment.center,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.close_rounded),
                                label: Text(l10n.modulesClose),
                              ),
                              FilledButton.icon(
                                onPressed: _loadEntry,
                                icon: const Icon(Icons.refresh_rounded),
                                label: Text(l10n.retry),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
