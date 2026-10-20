import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

typedef _IntNative = Int32 Function();
typedef _IntDart = int Function();
typedef _CtlNative = Int32 Function(Int32 value);
typedef _CtlDart = int Function(int value);
typedef _StringNative = IntPtr Function(Pointer<Uint8> buffer, Size capacity);
typedef _StringDart = int Function(Pointer<Uint8> buffer, int capacity);
typedef _ProfileNative = Int32 Function(
  Int32 uid,
  Int32 rootUid,
  Uint64 caps,
  Pointer<Uint8> domain,
  Size domainLength,
  Int32 namespace,
);
typedef _ProfileDart = int Function(
  int uid,
  int rootUid,
  int caps,
  Pointer<Uint8> domain,
  int domainLength,
  int namespace,
);
typedef _UidNative = Int32 Function(Int32 uid);
typedef _UidDart = int Function(int uid);

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
  static final _ProfileDart? _setProfile = _lookupProfile('ncore_set_profile');
  static final _UidDart? _deleteProfile = _lookupUid('ncore_del_uid');
  static final _UidDart? _hasProfile = _lookupUid('ncore_has_uid');
  static final _StringDart? _listProfiles = _lookupString(
    'ncore_list_profiles',
  );

  static final bool available = _ctl != null && _isGki != null;
  static final bool profileApiAvailable =
      _setProfile != null &&
      _deleteProfile != null &&
      _hasProfile != null &&
      _listProfiles != null;

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

  static _ProfileDart? _lookupProfile(String name) {
    final library = _library;
    if (library == null) return null;
    try {
      return library.lookupFunction<_ProfileNative, _ProfileDart>(name);
    } catch (_) {
      return null;
    }
  }

  static _UidDart? _lookupUid(String name) {
    final library = _library;
    if (library == null) return null;
    try {
      return library.lookupFunction<_UidNative, _UidDart>(name);
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

  static String? get profiles => _readString(_listProfiles);

  static bool setProfile({
    required int uid,
    required int rootUid,
    required int caps,
    required String domain,
    required int namespace,
  }) {
    final function = _setProfile;
    if (function == null) return false;
    _ensureInitialized();

    final bytes = utf8.encode(domain);
    final buffer = calloc<Uint8>(bytes.isEmpty ? 1 : bytes.length);
    try {
      if (bytes.isNotEmpty) {
        buffer.asTypedList(bytes.length).setAll(0, bytes);
      }
      return function(uid, rootUid, caps, buffer, bytes.length, namespace) == 0;
    } finally {
      calloc.free(buffer);
    }
  }

  static bool deleteProfile(int uid) {
    final function = _deleteProfile;
    if (function == null) return false;
    _ensureInitialized();
    return function(uid) == 0;
  }

  static bool? hasProfile(int uid) {
    final function = _hasProfile;
    if (function == null) return null;
    _ensureInitialized();
    final result = function(uid);
    return result < 0 ? null : result == 1;
  }

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
