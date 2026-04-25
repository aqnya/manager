import 'package:posix/posix.dart';

String getKernelRelease() {
  final uts = uname();
  return uts.release;
}
