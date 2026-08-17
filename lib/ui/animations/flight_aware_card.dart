import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:flutter/cupertino.dart';

/// Keeps layout space while the overlay owns the visible card.
/// Instant hide/show — animated opacity causes the double-flash.
class FlightAwareCard extends StatelessWidget {
  const FlightAwareCard({
    super.key,
    required this.card,
    required this.inFlight,
    required this.child,
  });

  final PlayingCardModel card;
  final bool inFlight;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: inFlight,
      child: Opacity(
        opacity: inFlight ? 0.0 : 1.0,
        child: child,
      ),
    );
  }
}
