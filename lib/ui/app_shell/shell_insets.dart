import 'package:flutter/cupertino.dart';

/// Avatar + name + currency overlay height (status bar + bar content).
double shellTopBarHeight(BuildContext context) {
  return MediaQuery.paddingOf(context).top + 52;
}

/// Floating tab bar clearance (matches AppShell: 10 + system bottom + bar).
double shellBottomNavClearance(BuildContext context) {
  return 10 + MediaQuery.paddingOf(context).bottom + 64;
}
