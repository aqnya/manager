import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

final DynamicLibrary _libc =
    Platform.isAndroid ? DynamicLibrary.open('libc.so') : DynamicLibrary.process();

typedef NativeUname = Int32 Function(Pointer<Utsname>);
typedef DartUname = int Function(Pointer<Utsname>);

final DartUname _uname =
    _libc.lookupFunction<NativeUname, DartUname>('uname');

final class Utsname extends Struct {
  @Array(65)
  external Array<Int8> sysname;

  @Array(65)
  external Array<Int8> nodename;

  @Array(65)
  external Array<Int8> release;

  @Array(65)
  external Array<Int8> version;

  @Array(65)
  external Array<Int8> machine;
}

String getKernelRelease() {
  final uts = calloc<Utsname>();

  try {
    if (_uname(uts) != 0) return "uname failed";

    return uts.ref.release
        .cast<Int8>()
        .toDartString();
  } finally {
    calloc.free(uts);
  }
}