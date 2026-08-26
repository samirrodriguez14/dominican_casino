import 'package:dominican_casino/ui/animations/card_motion.dart';
import 'package:flutter/cupertino.dart';

/// Flight destination/origin slot. The [key] always resolves to a fixed-size
/// box so in-flight hiding can never collapse the measured center to the
/// slot's top-left (which made flyers land high/left of the real card).
class FlightAwareCard extends StatelessWidget {
  const FlightAwareCard({
    super.key,
    required this.motion,
    required this.cardId,
    required this.width,
    this.heightMultiplyer = 1.4,
    required this.child,
  });

  final CardMotionController motion;
  final String cardId;
  final double width;
  final double heightMultiplyer;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final height = width * heightMultiplyer;
    // Pass [child] through ListenableBuilder so card faces are not rebuilt
    // on every markInFlight / clearInFlight — only visibility toggles.
    return ListenableBuilder(
      listenable: motion,
      child: child,
      builder: (context, cachedChild) {
        final inFlight = motion.isInFlight(cardId);
        // Tight size first — GlobalKey measurement uses this box, not the child.
        return SizedBox(
          width: width,
          height: height,
          child: IgnorePointer(
            ignoring: inFlight,
            child: Visibility(
              visible: !inFlight,
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: cachedChild!,
            ),
          ),
        );
      },
    );
  }
}
