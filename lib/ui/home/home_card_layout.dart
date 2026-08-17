import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

const homeCardWidthFactor = 0.90;
const homeCardMaxWidth = 420.0;
const homeCardAspect = 2.5 / 3.5;

/// Width for the home login / privacy / how-to cards (playing-card ratio).
double homeCardWidth(BoxConstraints constraints, {double verticalInset = 0}) {
  final fromWidth = (constraints.maxWidth * homeCardWidthFactor).clamp(
    220.0,
    homeCardMaxWidth,
  );
  final fromHeight = (constraints.maxHeight - verticalInset) * homeCardAspect;
  if (fromHeight.isFinite && fromHeight > 0) {
    return math.min(fromWidth, fromHeight);
  }
  return fromWidth;
}
