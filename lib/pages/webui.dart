import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nekosu/apps.dart';
import 'package:nekosu/ffi.dart';
import 'package:nekosu/l10n/app_localizations.dart';
import 'package:nekosu/modules.dart';
import 'package:webview_flutter/webview_flutter.dart';

const _webUiBridgePath = '/__nekosu_webui_bridge.js';

const _webUiBridgeJs = r'''
(function () {
  'use strict';
  if (window.ksu) return;

  var prefix = '__NEKOSU_WEBUI__:';

  function invoke(method, payload) {
    var response = window.prompt(prefix + JSON.stringify({
      method: method,
      payload: payload || {}
    }));
    if (response === null) {
      throw new Error('NekoSU WebUI bridge is unavailable');
    }
    var result = JSON.parse(response);
    if (!result.ok) {
      throw new Error(result.error || 'NekoSU WebUI bridge call failed');
    }
    return result.value;
  }

  function normalizeOptions(options) {
    if (typeof options === 'string') {
      try { return JSON.parse(options); } catch (error) { return {}; }
    }
    return options && typeof options === 'object' ? options : {};
  }

  function resolveCallback(callback) {
    if (typeof callback === 'string' && callback.length > 0) {
      return window[callback];
    }
    return callback;
  }

  function parseArguments(args) {
    if (Array.isArray(args)) return args;
    if (typeof args !== 'string' || args.length === 0) return [];
    try {
      var parsed = JSON.parse(args);
      return Array.isArray(parsed) ? parsed : [];
    } catch (error) {
      return [];
    }
  }

  function emitCommandResult(callback, result) {
    try {
      if (result.stdout) callback.stdout.emit('data', result.stdout);
      if (result.stderr) callback.stderr.emit('data', result.stderr);
      callback.emit('exit', result.code);
      if (result.code !== 0) {
        var error = new Error(result.stderr || 'Command failed');
        error.exitCode = result.code;
        callback.emit('error', error);
      }
    } catch (error) {
      console.error(error);
    }
  }

  window.ksu = {
    exec: function (command, options, callback) {
      if (typeof options === 'function') {
        callback = options;
        options = {};
      } else if (callback === undefined && typeof options === 'string') {
        try {
          JSON.parse(options);
        } catch (error) {
          if (typeof window[options] === 'function') {
            callback = options;
            options = {};
          }
        }
      }
      var payload = {
        command: String(command),
        options: normalizeOptions(options)
      };
      var target = resolveCallback(callback);
      if (typeof target === 'function') {
        try {
          var result = invoke('exec', payload);
          setTimeout(function () {
            target(result.code, result.stdout, result.stderr);
          }, 0);
        } catch (error) {
          setTimeout(function () {
            target(-1, '', String(error && error.message || error));
          }, 0);
        }
        return;
      }
      return invoke('exec', payload).stdout;
    },
    spawn: function (command, args, options, callback) {
      if (typeof options === 'function') {
        callback = options;
        options = {};
      }
      var target = resolveCallback(callback);
      if (!target || typeof target.emit !== 'function') return;
      try {
        var result = invoke('spawn', {
          command: String(command),
          args: parseArguments(args),
          options: normalizeOptions(options)
        });
        setTimeout(function () {
          emitCommandResult(target, result);
        }, 0);
      } catch (error) {
        setTimeout(function () {
          var commandError = new Error(String(error && error.message || error));
          commandError.exitCode = -1;
          target.emit('error', commandError);
          target.emit('exit', -1);
        }, 0);
      }
    },
    toast: function (message) {
      invoke('toast', { message: String(message) });
    },
    moduleInfo: function () {
      return invoke('moduleInfo', {});
    },
    listPackages: function (type) {
      return invoke('listPackages', { type: String(type || '') });
    },
    getPackagesInfo: function (packageNames) {
      return invoke('getPackagesInfo', {
        packages: String(packageNames || '[]')
      });
    },
    exit: function () {
      invoke('exit', {});
    },
    enableEdgeToEdge: function (enable) {
      invoke('edgeToEdge', { enable: !!enable });
    },
    fullScreen: function (enable) {
      invoke('fullScreen', { enable: !!enable });
    }
  };
})();
''';

class WebUiPage extends StatefulWidget {
  const WebUiPage({super.key, required this.entryPath, required this.module});

  final String entryPath;
  final ModuleInfo module;

  @override
  State<WebUiPage> createState() => _WebUiPageState();
}

class _WebUiPageState extends State<WebUiPage> {
  static const _bridgePromptPrefix = '__NEKOSU_WEBUI__:';

  late final WebViewController _controller;
  _WebUiServer? _server;
  Uri? _entryUri;

  bool _viewSized = false;
  bool _initialLoadScheduled = false;
  bool _initialLoadStarted = false;
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
      (request) => _handlePrompt(request.message, request.defaultText),
    );
    final entry = File(widget.entryPath);
    if (!await entry.exists()) {
      _showError('WebUI entry file is unavailable');
      return;
    }

    final server = _WebUiServer(entry.parent);
    try {
      final baseUri = await server.start();
      if (!mounted) {
        await server.close();
        return;
      }
      _server = server;
      final userAgent = await _controller.getUserAgent();
      await _controller.setUserAgent(
        [
          if (userAgent != null && userAgent.trim().isNotEmpty)
            userAgent.trim(),
          'NekoSUWebUI/${server.token}',
        ].join(' '),
      );
      _entryUri = baseUri.resolve(entry.uri.pathSegments.last);
      _scheduleInitialLoad();
    } catch (error) {
      await server.close();
      _showError(error.toString());
    }
  }

  void _scheduleInitialLoad() {
    if (!mounted ||
        _entryUri == null ||
        !_viewSized ||
        _initialLoadScheduled ||
        _initialLoadStarted) {
      return;
    }
    _initialLoadScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialLoadScheduled = false;
      if (!mounted || _initialLoadStarted || _entryUri == null) return;
      _initialLoadStarted = true;
      unawaited(_loadEntry());
    });
  }

  Future<void> _loadEntry() async {
    final entryUri = _entryUri;
    if (!mounted || entryUri == null) return;
    setState(() {
      _loading = true;
      _progress = 0;
      _error = null;
    });
    await _controller.loadRequest(entryUri);
  }

  void _showError(Object error) {
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = error.toString();
    });
  }

  void _retry() {
    if (_entryUri == null) {
      unawaited(_initialize());
    } else {
      unawaited(_loadEntry());
    }
  }

  @override
  void dispose() {
    final server = _server;
    _server = null;
    if (server != null) unawaited(server.close());
    super.dispose();
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

  Future<String> _handlePrompt(String message, String? defaultText) async {
    if (!message.startsWith(_bridgePromptPrefix)) {
      return _showPrompt(message, defaultText);
    }
    try {
      final decoded = jsonDecode(message.substring(_bridgePromptPrefix.length));
      if (decoded is! Map) {
        throw const FormatException('Invalid WebUI bridge request');
      }
      final payload = decoded['payload'];
      final value = await _handleBridgeCall(
        decoded['method']?.toString() ?? '',
        payload is Map ? payload.cast<String, dynamic>() : const {},
      );
      return jsonEncode({'ok': true, 'value': value});
    } catch (error) {
      return jsonEncode({'ok': false, 'error': error.toString()});
    }
  }

  Future<Object?> _handleBridgeCall(
    String method,
    Map<String, dynamic> payload,
  ) async {
    switch (method) {
      case 'exec':
      case 'spawn':
        return await _runRootCommand(payload);
      case 'toast':
        return _showToast(payload['message']?.toString() ?? '');
      case 'moduleInfo':
        return _moduleInfoJson();
      case 'listPackages':
        return await _listPackages(payload['type']?.toString() ?? '');
      case 'getPackagesInfo':
        return await _getPackagesInfo(payload['packages']?.toString() ?? '[]');
      case 'exit':
        return _exitWebUi();
      case 'fullScreen':
        return await _setFullScreen(payload['enable'] == true);
      case 'edgeToEdge':
        return null;
      default:
        throw UnsupportedError('Unsupported WebUI bridge method: $method');
    }
  }

  Future<Object?> _runRootCommand(Map<String, dynamic> payload) async {
    final command = _composeCommand(payload);
    final output = await Isolate.run(() => NcoreFfi.webUiExec(command));
    if (output == null) {
      throw StateError('WebUI command bridge is unavailable');
    }
    final decoded = jsonDecode(output);
    if (decoded is! Map) {
      throw const FormatException('Invalid WebUI command result');
    }
    return decoded;
  }

  String _composeCommand(Map<String, dynamic> payload) {
    final buffer = StringBuffer();
    final rawOptions = payload['options'];
    final options = rawOptions is Map
        ? rawOptions.cast<String, dynamic>()
        : const <String, dynamic>{};

    final cwd = options['cwd']?.toString().trim() ?? '';
    if (cwd.isNotEmpty) buffer.write('cd ${_shellQuote(cwd)};');

    final rawEnvironment = options['env'];
    if (rawEnvironment is Map) {
      rawEnvironment.forEach((key, value) {
        final name = key.toString();
        if (RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(name)) {
          buffer.write('export $name=${_shellQuote(value.toString())};');
        }
      });
    }

    buffer.write(payload['command']?.toString() ?? '');
    final arguments = payload['args'];
    if (arguments is List) {
      for (final argument in arguments) {
        buffer.write(' ${_shellQuote(argument.toString())}');
      }
    }
    return buffer.toString();
  }

  static String _shellQuote(String value) {
    return "'${value.replaceAll("'", "'\\''")}'";
  }

  Object? _showToast(String message) {
    if (!mounted || message.isEmpty) return null;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
    return null;
  }

  String _moduleInfoJson() {
    final module = widget.module;
    return jsonEncode({
      'moduleDir': '/data/adb/modules/${module.id}',
      'id': module.id,
      'name': module.name,
      'version': module.version,
      'versionCode': module.versionCode,
      'author': module.author,
      'description': module.description,
      'enabled': module.enabled,
    });
  }

  Future<String> _listPackages(String type) async {
    final apps = await AppsPlatform.listApps();
    final normalized = type.toLowerCase();
    final packages =
        apps
            .where(
              (app) => switch (normalized) {
                'system' => app.isSystem,
                'user' => !app.isSystem,
                _ => true,
              },
            )
            .map((app) => app.packageName)
            .toList()
          ..sort();
    return jsonEncode(packages);
  }

  Future<String> _getPackagesInfo(String packageNamesJson) async {
    final requested = jsonDecode(packageNamesJson);
    final names = requested is List
        ? requested.map((name) => name.toString()).toList()
        : const <String>[];
    final apps = {
      for (final app in await AppsPlatform.listApps()) app.packageName: app,
    };
    final result = <Map<String, Object?>>[];
    for (final name in names) {
      final app = apps[name];
      if (app == null) {
        result.add({
          'packageName': name,
          'error': 'Package not found or inaccessible',
        });
        continue;
      }
      result.add({
        'packageName': app.packageName,
        'versionName': '',
        'versionCode': 0,
        'appLabel': app.name,
        'isSystem': app.isSystem,
        'uid': app.uid,
      });
    }
    return jsonEncode(result);
  }

  Object? _exitWebUi() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).maybePop();
    });
    return null;
  }

  Future<Object?> _setFullScreen(bool enable) async {
    await SystemChrome.setEnabledSystemUIMode(
      enable ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
    );
    return null;
  }

  Widget _buildWebView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!_viewSized &&
            constraints.maxWidth > 0 &&
            constraints.maxHeight > 0) {
          _viewSized = true;
          _scheduleInitialLoad();
        }
        return WebViewWidget(controller: _controller);
      },
    );
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
              _buildWebView(),
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
                                onPressed: _retry,
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

class _WebUiServer {
  _WebUiServer(this.root);

  static final _random = Random.secure();

  final Directory root;
  final String token = List.generate(
    24,
    (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();

  HttpServer? _server;

  Future<Uri> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.autoCompress = true;
    _server = server;
    server.listen(_handleRequest);
    return Uri(
      scheme: 'http',
      host: InternetAddress.loopbackIPv4.address,
      port: server.port,
      path: '/',
    );
  }

  Future<void> close() async {
    final server = _server;
    _server = null;
    await server?.close(force: true);
  }

  Future<void> _handleRequest(HttpRequest request) async {
    try {
      if (request.method != 'GET' && request.method != 'HEAD') {
        await _writeText(
          request.response,
          HttpStatus.methodNotAllowed,
          'Method not allowed',
        );
        return;
      }

      final userAgent = request.headers.value(HttpHeaders.userAgentHeader);
      if (userAgent == null || !userAgent.contains('NekoSUWebUI/$token')) {
        await _notFound(request.response);
        return;
      }

      if (request.uri.path == _webUiBridgePath) {
        await _writeBytes(
          request.response,
          'text/javascript; charset=utf-8',
          utf8.encode(_webUiBridgeJs),
        );
        return;
      }

      final relative = request.uri.pathSegments.toList(growable: true);
      if (relative.any(_invalidSegment)) {
        await _notFound(request.response);
        return;
      }
      if (relative.isEmpty) relative.add('index.html');

      var file = File([root.path, ...relative].join(Platform.pathSeparator));
      if (await FileSystemEntity.type(file.path, followLinks: true) ==
          FileSystemEntityType.directory) {
        if (!request.uri.path.endsWith('/')) {
          request.response
            ..statusCode = HttpStatus.movedPermanently
            ..headers.set(HttpHeaders.locationHeader, '${request.uri.path}/');
          await request.response.close();
          return;
        }
        file = File([file.path, 'index.html'].join(Platform.pathSeparator));
      }

      if (await FileSystemEntity.type(file.path, followLinks: true) !=
          FileSystemEntityType.file) {
        await _notFound(request.response);
        return;
      }

      final contentType = _contentTypeFor(file.path);
      if (contentType.startsWith('text/html')) {
        final html = utf8.decode(
          await file.readAsBytes(),
          allowMalformed: true,
        );
        await _writeBytes(
          request.response,
          contentType,
          utf8.encode(_injectBridge(html)),
        );
        return;
      }

      _setHeaders(request.response, contentType, await file.length());

      if (request.method == 'HEAD') {
        await request.response.close();
        return;
      }

      await request.response.addStream(file.openRead());
      await request.response.close();
    } catch (_) {
      await _writeText(
        request.response,
        HttpStatus.internalServerError,
        'Unable to load WebUI resource',
      );
    }
  }

  static bool _invalidSegment(String segment) {
    return segment.isEmpty ||
        segment == '.' ||
        segment == '..' ||
        segment.contains('/') ||
        segment.contains('\\');
  }

  static Future<void> _notFound(HttpResponse response) {
    return _writeText(response, HttpStatus.notFound, 'Not found');
  }

  static Future<void> _writeText(
    HttpResponse response,
    int status,
    String message,
  ) async {
    response
      ..statusCode = status
      ..headers.contentType = ContentType.text
      ..write(message);
    await response.close();
  }

  static Future<void> _writeBytes(
    HttpResponse response,
    String contentType,
    List<int> bytes,
  ) async {
    _setHeaders(response, contentType, bytes.length);
    response.add(bytes);
    await response.close();
  }

  static void _setHeaders(
    HttpResponse response,
    String contentType,
    int contentLength,
  ) {
    response.headers
      ..contentType = ContentType.parse(contentType)
      ..set(HttpHeaders.cacheControlHeader, 'no-store')
      ..set('X-Content-Type-Options', 'nosniff')
      ..contentLength = contentLength;
  }

  static String _injectBridge(String html) {
    final tag = '<script src="$_webUiBridgePath"></script>';
    final head = RegExp(
      r'<head\b[^>]*>',
      caseSensitive: false,
    ).firstMatch(html);
    if (head != null) {
      return html.replaceRange(head.end, head.end, tag);
    }
    final htmlTag = RegExp(
      r'<html\b[^>]*>',
      caseSensitive: false,
    ).firstMatch(html);
    if (htmlTag != null) {
      return html.replaceRange(htmlTag.end, htmlTag.end, '<head>$tag</head>');
    }
    final body = RegExp(
      r'<body\b[^>]*>',
      caseSensitive: false,
    ).firstMatch(html);
    if (body != null) {
      return html.replaceRange(body.end, body.end, tag);
    }
    return '$tag$html';
  }

  static String _contentTypeFor(String path) {
    final dot = path.lastIndexOf('.');
    final extension = dot < 0 ? '' : path.substring(dot + 1).toLowerCase();
    return switch (extension) {
      'html' || 'htm' => 'text/html; charset=utf-8',
      'css' => 'text/css; charset=utf-8',
      'js' || 'mjs' => 'text/javascript; charset=utf-8',
      'json' || 'map' => 'application/json; charset=utf-8',
      'txt' => 'text/plain; charset=utf-8',
      'xml' => 'application/xml; charset=utf-8',
      'svg' => 'image/svg+xml',
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      'ico' => 'image/x-icon',
      'woff' => 'font/woff',
      'woff2' => 'font/woff2',
      'ttf' => 'font/ttf',
      'otf' => 'font/otf',
      'wasm' => 'application/wasm',
      'mp4' => 'video/mp4',
      'webm' => 'video/webm',
      'mp3' => 'audio/mpeg',
      'wav' => 'audio/wav',
      _ => 'application/octet-stream',
    };
  }
}
