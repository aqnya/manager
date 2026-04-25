import 'dart:io';

Future<String> getKernelReleaseByCmd() async {
  try {
    final result = await Process.run('/system/bin/uname', ['-r']);

    if (result.exitCode == 0) {
      return (result.stdout as String).trim();
    } else {
      return "uname failed: ${result.stderr}";
    }
  } catch (e) {
    return "error: $e";
  }
}