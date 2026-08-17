import 'package:dominican_casino/game_control/interfaces/card_event.dart';
import 'package:dominican_casino/game_control/interfaces/zone.dart';
import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:flutter/cupertino.dart';

class CardFlightRequest {
  final CardMoveEvent event;
  final Offset? fromGlobalCenter;
  final GlobalKey? toKey;
  final GlobalKey? fromKey;
  final bool startFaceUp;
  final bool endFaceUp;
  final bool flip;
  final double startWidth;
  final double endWidth;
  final bool hapticOnLaunch;

  const CardFlightRequest({
    required this.event,
    this.fromGlobalCenter,
    this.toKey,
    this.fromKey,
    this.startFaceUp = true,
    this.endFaceUp = true,
    this.flip = false,
    this.startWidth = 60,
    this.endWidth = 60,
    this.hapticOnLaunch = true,
  });

  PlayingCardModel get card => event.card;
  String get cardId => event.card.id;
  Zone get from => event.from;
  Zone get to => event.to;
}

typedef CardFlightRunner =
    Future<void> Function(
      List<CardFlightRequest> flights, {
      VoidCallback? onLanded,
    });

class ShuffleSource {
  final Offset origin;
  final int count;

  const ShuffleSource({required this.origin, required this.count});
}

class ShuffleRequest {
  final List<ShuffleSource> sources;
  final Offset center;
  final Offset deckTarget;
  final double cardWidth;

  const ShuffleRequest({
    required this.sources,
    required this.center,
    required this.deckTarget,
    this.cardWidth = 60,
  });
}

typedef ShuffleRunner =
    Future<void> Function(
      ShuffleRequest request, {
      Future<void> Function()? onSquared,
    });

class CardMotionController extends ChangeNotifier {
  final Set<String> _inFlight = {};
  CardFlightRunner? runner;
  ShuffleRunner? shuffleRunner;
  bool _shuffling = false;

  bool get isShuffling => _shuffling;
  bool get hasFlights => _inFlight.isNotEmpty || _shuffling;
  bool isInFlight(String cardId) => _inFlight.contains(cardId);
  bool isInFlightCard(PlayingCardModel card) => isInFlight(card.id);
  bool anyInFlight(Iterable<PlayingCardModel> cards) =>
      cards.any((c) => isInFlight(c.id));

  void markInFlight(Iterable<String> ids) {
    _inFlight.addAll(ids);
    notifyListeners();
  }

  void clearInFlight([Iterable<String>? ids]) {
    if (ids == null) {
      _inFlight.clear();
    } else {
      _inFlight.removeAll(ids);
    }
    notifyListeners();
  }

  void setShuffling(bool value) {
    if (_shuffling == value) return;
    _shuffling = value;
    notifyListeners();
  }

  Future<void> run(List<CardFlightRequest> flights) async {
    if (flights.isEmpty) return;
    final run = runner;
    if (run == null) {
      clearInFlight(flights.map((f) => f.cardId));
      return;
    }
    await run(
      flights,
      onLanded: () => clearInFlight(flights.map((f) => f.cardId)),
    );
  }

  Future<void> runShuffle(
    ShuffleRequest request, {
    Future<void> Function()? onSquared,
  }) async {
    if (request.sources.isEmpty) {
      await onSquared?.call();
      return;
    }
    final run = shuffleRunner;
    if (run == null) {
      await onSquared?.call();
      return;
    }
    await run(request, onSquared: onSquared);
  }
}
