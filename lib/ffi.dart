import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

typedef _IntNative = Int32 Function();
typedef _IntDart = int Function();
typedef _CtlNative = Int32 Function(Int32 value);
typedef _CtlDart = int Function(int value);
typedef _StringNative = IntPtr Function(Pointer<Uint8> buffer, Size capacity);
typedef _StringDart = int Function(Pointer<Uint8> buffer, int capacity);

class NcoreFfi {
  NcoreFfi._();

  static final DynamicLibrary? _library = _openLibrary();
  static final _IntDart? _init = _lookupInt('ncore_init');
  static final _CtlDart? _ctl = _lookupCtl('ncore_ctl');
  static final _IntDart? _isGki = _lookupInt('ncore_is_gki');
  static final _StringDart? _kernelVersion = _lookupString(
    'ncore_kernel_version',
  );
  static final _StringDart? _kernelRelease = _lookupString(
    'ncore_kernel_release',
  );
  static final _StringDart? _moduleVersion = _lookupString(
    'ncore_module_version',
  );

  static final bool available = _ctl != null && _isGki != null;

  static bool _initialized = false;

  static DynamicLibrary? _openLibrary() {
    if (!Platform.isAndroid) return null;
    try {
      return DynamicLibrary.open('libncore_ffi.so');
    } catch (_) {
      return null;
    }
  }

  static _IntDart? _lookupInt(String name) {
    final library = _library;
    if (library == null) return null;
    try {
      return library.lookupFunction<_IntNative, _IntDart>(name);
    } catch (_) {
      return null;
    }
  }

  static _CtlDart? _lookupCtl(String name) {
    final library = _library;
    if (library == null) return null;
    try {
      return library.lookupFunction<_CtlNative, _CtlDart>(name);
    } catch (_) {
      return null;
    }
  }

  static _StringDart? _lookupString(String name) {
    final library = _library;
    if (library == null) return null;
    try {
      return library.lookupFunction<_StringNative, _StringDart>(name);
    } catch (_) {
      return null;
    }
  }

  static void _ensureInitialized() {
    if (_initialized) return;
    _initialized = true;
    _init?.call();
  }

  static int ctl(int value) {
    _ensureInitialized();
    return _ctl?.call(value) ?? -1;
  }

  static bool get isInstalled => ctl(1) == 0;

  static bool get isGki {
    _ensureInitialized();
    return _isGki?.call() == 1;
  }

  static String? get kernelVersion => _readString(_kernelVersion);

  static String? get kernelRelease => _readString(_kernelRelease);

  static String? get moduleVersion => _readString(_moduleVersion);

  static String? _readString(_StringDart? function) {
    if (function == null) return null;
    _ensureInitialized();

    var capacity = 128;
    for (var attempt = 0; attempt < 3; attempt++) {
      final buffer = calloc<Uint8>(capacity);
      try {
        final length = function(buffer, capacity);
        if (length < 0) return null;
        if (length < capacity) {
          return buffer.cast<Utf8>().toDartString(length: length);
        }
        if (length > 64 * 1024) return null;
        capacity = length + 1;
      } finally {
        calloc.free(buffer);
      }
    }
    return null;
  }
}
