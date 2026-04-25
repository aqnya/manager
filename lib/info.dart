import 'dart:ffi';
import 'package:ffi/ffi.dart';

final _lib = DynamicLibrary.open('libncore.so');

final _getKernelRelease = _lib
    .lookup<NativeFunction<Int32 Function(Pointer<Utf8>, Size)>>(
      'get_kernel_release',
    )
    .asFunction<int Function(Pointer<Utf8>, int)>();

String getKernelRelease() {
  final buf = calloc<Uint8>(256);
  try {
    final n = _getKernelRelease(buf.cast<Utf8>(), 256);
    if (n < 0) return 'uname failed';

    return buf.cast<Utf8>().toDartString(length: n);
  } finally {
    calloc.free(buf);
  }
}
