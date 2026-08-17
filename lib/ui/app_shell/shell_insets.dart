import 'package:flutter/cupertino.dart';

/// Avatar + name + currency overlay height (status bar + bar content).
double shellTopBarHeight(BuildContext context) {
  return MediaQuery.paddingOf(context).top + 52;
}
