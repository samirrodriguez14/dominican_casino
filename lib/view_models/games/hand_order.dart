import 'package:dominican_casino/models/playing_card_model.dart';

/// Local-only fan order. Hand order is not written to the match document,
/// so remote replaces must re-apply it or the fan snaps back.
void applyPreferredHandOrder(
  List<PlayingCardModel> incoming,
  List<String> preferredIds,
) {
  if (incoming.isEmpty || preferredIds.isEmpty) return;

  final byId = <String, PlayingCardModel>{
    for (final c in incoming) c.id: c,
  };
  final ordered = <PlayingCardModel>[];
  for (final id in preferredIds) {
    final next = byId.remove(id);
    if (next != null) ordered.add(next);
  }
  // Brand-new hand (deal) — no overlap with the remembered fan.
  if (ordered.isEmpty) return;
  ordered.addAll(byId.values);
  if (_sameHandIds(incoming, ordered)) return;
  incoming
    ..clear()
    ..addAll(ordered);
}

List<String> handOrderIds(List<PlayingCardModel> hand) => [
  for (final c in hand) c.id,
];

bool _sameHandIds(List<PlayingCardModel> a, List<PlayingCardModel> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i].id != b[i].id) return false;
  }
  return true;
}
