import 'package:flutter/foundation.dart';
import 'ncore.dart';

enum InstallStatus { installed, notInstalled }

class HomeViewModel extends ChangeNotifier {
  final InstallStatus installStatus;
  final int suCount;
  final int ruleCount;

  HomeViewModel._({
    required this.installStatus,
    required this.suCount,
    required this.ruleCount,
  });

  factory HomeViewModel.init() {
    final result = Ncore().ctl(1);
    if (result == 0) {
      Ncore().ctl(3);
      // TODO: query RootDbHelper / RuleDbHelper for counts
      return HomeViewModel._(
        installStatus: InstallStatus.installed,
        suCount: 0,
        ruleCount: 0,
      );
    } else {
      return HomeViewModel._(
        installStatus: InstallStatus.notInstalled,
        suCount: 0,
        ruleCount: 0,
      );
    }
  }
}
