import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

final DynamicLibrary _lib = DynamicLibrary.open('libncore.so');

Pointer<Char> toCString(String s) => s.toNativeUtf8().cast<Char>();

T withCString<T>(String s, T Function(Pointer<Char>) fn) {
  final ptr = toCString(s);
  try {
    return fn(ptr);
  } finally {
    calloc.free(ptr);
  }
}

// ncore_init() -> c_int
final int Function() ncoreInit = _lib
    .lookupFunction<Int32 Function(), int Function()>('ncore_init');

// ncore_install() -> bool
final bool Function() ncoreInstall = _lib
    .lookupFunction<Bool Function(), bool Function()>('ncore_install');

// ncore_ctl(value: c_int) -> c_int
final int Function(int) ncoreCtl = _lib
    .lookupFunction<Int32 Function(Int32), int Function(int)>('ncore_ctl');

// ncore_set_profile(uid, caps, domain, namespace) -> c_int
final int Function(int, int, Pointer<Char>, int) ncoreSetProfile = _lib
    .lookupFunction<
      Int32 Function(Int32, Uint64, Pointer<Char>, Int32),
      int Function(int, int, Pointer<Char>, int)
    >('ncore_set_profile');

// ncore_add_selinux_rule(src, tgt, cls, perm, effect, invert) -> c_int
final int Function(
  Pointer<Char>,
  Pointer<Char>,
  Pointer<Char>,
  Pointer<Char>,
  int,
  bool,
)
ncoreAddSelinuxRule = _lib
    .lookupFunction<
      Int32 Function(
        Pointer<Char>,
        Pointer<Char>,
        Pointer<Char>,
        Pointer<Char>,
        Int32,
        Bool,
      ),
      int Function(
        Pointer<Char>,
        Pointer<Char>,
        Pointer<Char>,
        Pointer<Char>,
        int,
        bool,
      )
    >('ncore_add_selinux_rule');

// ncore_adduid(uid) -> c_int
final int Function(int) ncoreAddUid = _lib
    .lookupFunction<Int32 Function(Int32), int Function(int)>('ncore_adduid');

// ncore_deluid(uid) -> c_int
final int Function(int) ncoreDelUid = _lib
    .lookupFunction<Int32 Function(Int32), int Function(int)>('ncore_deluid');

// ncore_hasuid(uid) -> c_int  (-1=err, 0=false, 1=true)
final int Function(int) ncoreHasUid = _lib
    .lookupFunction<Int32 Function(Int32), int Function(int)>('ncore_hasuid');

// ncore_set_cap(uid, caps) -> c_int
final int Function(int, int) ncoreSetCap = _lib
    .lookupFunction<Int32 Function(Int32, Uint64), int Function(int, int)>(
      'ncore_set_cap',
    );

// ncore_get_cap(uid) -> u64
final int Function(int) ncoreGetCap = _lib
    .lookupFunction<Uint64 Function(Int32), int Function(int)>('ncore_get_cap');

// ncore_del_cap(uid) -> c_int
final int Function(int) ncoreDelCap = _lib
    .lookupFunction<Int32 Function(Int32), int Function(int)>('ncore_del_cap');

class NCore {
  static int init() => ncoreInit();

  static bool isInstalled() => ncoreInstall();

  static int ctl(int value) => ncoreCtl(value);

  static int setProfile(int uid, int caps, String domain, int namespace) =>
      withCString(domain, (d) => ncoreSetProfile(uid, caps, d, namespace));

  static int addSelinuxRule(
    String src,
    String tgt,
    String cls,
    String perm,
    int effect,
    bool invert,
  ) => withCString(
    src,
    (s) => withCString(
      tgt,
      (t) => withCString(
        cls,
        (c) => withCString(
          perm,
          (p) => ncoreAddSelinuxRule(s, t, c, p, effect, invert),
        ),
      ),
    ),
  );

  static int addUid(int uid) => ncoreAddUid(uid);
  static int delUid(int uid) => ncoreDelUid(uid);

  /// returns null on error
  static bool? hasUid(int uid) {
    final r = ncoreHasUid(uid);
    if (r < 0) return null;
    return r == 1;
  }

  static int setCap(int uid, int caps) => ncoreSetCap(uid, caps);
  static int getCap(int uid) => ncoreGetCap(uid);
  static int delCap(int uid) => ncoreDelCap(uid);
}
