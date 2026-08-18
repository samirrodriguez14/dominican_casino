import 'dart:math' as math;

import 'package:dominican_casino/style/app_theme.dart';
import 'package:flutter/cupertino.dart';

const homeCardWidthFactor = 0.90;
const homeCardMaxWidth = 420.0;
const homeCardAspect = 2.5 / 3.5;

/// Login fan: a bit smaller than the old single card so side peeks can show.
const homeCarouselWidthFactor = 0.72;
const homeCarouselMaxWidth = 300.0;

/// Stage height of the home 3-card fan, matching [StackedCardCarousel].
double homeCarouselStageHeight(BoxConstraints constraints) {
  final fromWidth = (constraints.maxWidth * homeCarouselWidthFactor).clamp(
    180.0,
    homeCarouselMaxWidth,
  );
  var width = fromWidth;
  final maxForPeek = (constraints.maxWidth / 1.38).clamp(
    180.0,
    homeCarouselMaxWidth,
  );
  if (width > maxForPeek) width = maxForPeek;
  final fromHeight = (constraints.maxHeight - 36) * homeCardAspect;
  if (fromHeight.isFinite && fromHeight > 0) {
    width = math.min(width, fromHeight);
  }
  return width / homeCardAspect + 36;
}

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

/// Shared playing-card chrome for the home fan.
class HomeCardFace extends StatelessWidget {
  const HomeCardFace({super.key, required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    return AspectRatio(
      aspectRatio: homeCardAspect,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: theme.textPrimary.withValues(alpha: .14),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withValues(alpha: .30),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(borderRadius: BorderRadius.circular(18), child: child),
      ),
    );
  }
}

class HomeCardEyebrow extends StatelessWidget {
  const HomeCardEyebrow(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    return Text(
      label,
      style: theme.caption.copyWith(
        color: theme.textPrimary.withValues(alpha: .72),
        letterSpacing: 3.2,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
