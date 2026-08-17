import 'package:dominican_casino/ui/animations/card_motion.dart';
import 'package:flutter/cupertino.dart';

/// Keeps layout space while the overlay owns the visible card.
/// Listens to [motion] directly so in-flight changes do not require a full
/// board [ChangeNotifier] rebuild.
class FlightAwareCard extends StatelessWidget {
  const FlightAwareCard({
    super.key,
    required this.motion,
    required this.cardId,
    required this.child,
  });

  final CardMotionController motion;
  final String cardId;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: motion,
      builder: (context, _) {
        final inFlight = motion.isInFlight(cardId);
        // Offstage: still laid out (slot stays put) but not painted — cheaper
        // than Opacity(0), which creates a saveLayer every frame.
        return IgnorePointer(
          ignoring: inFlight,
          child: Offstage(
            offstage: inFlight,
            child: child,
          ),
        );
      },
    );
  }
}
