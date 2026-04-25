import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

typedef NativeSyscall = Int64 Function(Int64 number, Pointer<Void> arg);
typedef DartSyscall = int Function(int number, Pointer<Void> arg);

String getKernelReleaseDirectly() {
  final DynamicLibrary libc = DynamicLibrary.open('libc.so');

  final syscall = libc.lookupFunction<NativeSyscall, DartSyscall>('syscall');

  int syscallNumber;
  if (Platform.isAndroid) {
    final String arch = ProcessInfo.packageConfig ?? ""; 
    if (RegExp(r'arm64|aarch64').hasMatch(Platform.version.toLowerCase())) {
      syscallNumber = 160; 
    } else {
      syscallNumber = 63;
    }
  } else {
    return "Only for Android/Linux";
  }
  final Pointer<Uint8> buffer = calloc<Uint8>(65 * 5);

  try {
    final int result = syscall(syscallNumber, buffer.cast<Void>());

    if (result == 0) {
      final releasePtr = buffer.elementAt(130);
      return releasePtr.cast<Utf8>().toDartString();
    } else {
      return "Syscall failed: $result";
    }
  } catch (e) {
    return "Error: $e";
  } finally {
    calloc.free(buffer);
  }
}
