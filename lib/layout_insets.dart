import 'package:flutter/widgets.dart';

const floatingNavBarHeight = 68.0;
const floatingNavBarBottomGap = 16.0;

double floatingNavBarClearance(BuildContext context) {
  return MediaQuery.viewPaddingOf(context).bottom +
      floatingNavBarHeight +
      floatingNavBarBottomGap +
      18;
}
