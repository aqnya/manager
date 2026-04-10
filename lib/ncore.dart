// ncore.dart
import 'dart:ffi';

class Ncore {
  // static final DynamicLibrary _lib = DynamicLibrary.open('libncore.so');

  int ctl(int value) => -1;
  void helloLog() {}
  int addUid(int uid) => -1;
  int delUid(int uid) => -1;
  int hasUid(int uid) => -1;
  int addRule(String path, int statusBits) => -1;
  int delRule(String path) => -1;
  int setCap(int uid, int caps) => -1;
  int getCap(int uid) => -1;
  int delCap(int uid) => -1;
}
