import 'package:flutter/cupertino.dart';

/// Logo + currency overlay height (status bar + bar content).
double shellTopBarHeight(BuildContext context) {
  return MediaQuery.paddingOf(context).top + 52;
}
