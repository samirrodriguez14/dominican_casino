import 'package:dominican_casino/game_control/interfaces/card_event.dart';
import 'package:dominican_casino/game_control/interfaces/zone.dart';
import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/ui/animations/flight_layer.dart';
import 'package:flutter/cupertino.dart';

class CardFlightRequest {
  final CardMoveEvent event;

  /// Screen-global center; converted to layer-local by [CardFlightAnimator].
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
      VoidCallback? onLaunched,
    });

/// Owns [AnimationController]s created against a screen [TickerProvider].
///
/// Call [cancel] from [State.dispose] *before* `super.dispose()` so tickers
/// are not still active when [TickerProviderStateMixin] tears down.
class FlightTickerBag {
  FlightTickerBag(this.vsync);

  final TickerProvider vsync;
  final List<AnimationController> _live = [];
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  AnimationController create({required Duration duration}) {
    if (_cancelled) {
      throw StateError('FlightTickerBag cancelled');
    }
    final controller = AnimationController(vsync: vsync, duration: duration);
    _live.add(controller);
    return controller;
  }

  void release(AnimationController controller) {
    if (_live.remove(controller)) {
      controller.dispose();
    }
  }

  void cancel() {
    _cancelled = true;
    final controllers = List<AnimationController>.of(_live);
    _live.clear();
    for (final controller in controllers) {
      controller.dispose();
    }
  }
}

class ShuffleCardSource {
  final Offset origin;
  final double width;
  final bool faceUp;
  final PlayingCardModel? card;
  final String? hideId;

  const ShuffleCardSource({
    required this.origin,
    required this.width,
    required this.faceUp,
    this.card,
    this.hideId,
  });
}

class ShuffleRequest {
  /// Caps how many backs fly off a shoe/collected pile so a full deck
  /// stays a tight stack instead of a 2px-per-card tower.
  static const int maxPileBacks = 8;
  static const double pileBackStep = 2.0;

  static int pileBackCount(int cards) {
    if (cards <= 0) return 0;
    return cards < maxPileBacks ? cards : maxPileBacks;
  }

  final List<ShuffleCardSource> cards;
  final Offset center;
  final Offset deckTarget;
  final double targetCardWidth;

  const ShuffleRequest({
    required this.cards,
    required this.center,
    required this.deckTarget,
    this.targetCardWidth = 60,
  });
}

typedef ShuffleRunner =
    Future<void> Function(
      ShuffleRequest request, {
      Future<void> Function()? onFlyersAttached,
      Future<void> Function()? onHidden,
      Future<void> Function()? onSquared,
    });

class CardMotionController extends ChangeNotifier {
  final Set<String> _inFlight = {};
  CardFlightRunner? runner;
  ShuffleRunner? shuffleRunner;
  bool _disposed = false;

  /// Board-local flight host — set by [GeneralGameScreen].
  FlightLayerController? flightLayer;

  /// Fired once flight sprites are attached, before they start moving.
  /// Drag overlays use this to hand off without a visual gap.
  VoidCallback? onFlightsAttached;

  bool _shuffling = false;

  /// Bumps when the in-flight set changes. Card slots listen here so
  /// [markInFlight] / [clearInFlight] do not rebuild the whole board.
  final ValueNotifier<int> flightTick = ValueNotifier(0);

  bool get isShuffling => _shuffling;
  bool get hasFlights => _inFlight.isNotEmpty || _shuffling;
  bool isInFlight(String cardId) => _inFlight.contains(cardId);
  bool isInFlightCard(PlayingCardModel card) => isInFlight(card.id);
  bool anyInFlight(Iterable<PlayingCardModel> cards) =>
      cards.any((c) => isInFlight(c.id));

  void _notifyFlight() {
    if (_disposed) return;
    flightTick.value++;
  }

  void markInFlight(Iterable<String> ids) {
    if (_disposed) return;
    _inFlight.addAll(ids);
    _notifyFlight();
  }

  void clearInFlight([Iterable<String>? ids]) {
    if (_disposed) return;
    if (ids == null) {
      _inFlight.clear();
    } else {
      _inFlight.removeAll(ids);
    }
    _notifyFlight();
  }

  void setShuffling(bool value) {
    if (_disposed || _shuffling == value) return;
    _shuffling = value;
    // Shuffle toggles are rare — notify ChangeNotifier listeners (board
    // Offstage) without using flightTick for the whole tree.
    notifyListeners();
    _notifyFlight();
  }

  Future<void> run(List<CardFlightRequest> flights) async {
    if (_disposed || flights.isEmpty) return;
    final ids = flights.map((f) => f.cardId);
    final run = runner;
    if (run == null) {
      onFlightsAttached?.call();
      clearInFlight(ids);
      return;
    }
    try {
      await run(
        flights,
        onLanded: () => clearInFlight(ids),
        onLaunched: onFlightsAttached,
      );
    } finally {
      clearInFlight(ids);
    }
  }

  Future<void> runShuffle(
    ShuffleRequest request, {
    Future<void> Function()? onFlyersAttached,
    Future<void> Function()? onHidden,
    Future<void> Function()? onSquared,
  }) async {
    if (_disposed) return;
    if (request.cards.isEmpty) {
      await onSquared?.call();
      return;
    }
    final run = shuffleRunner;
    if (run == null) {
      await onSquared?.call();
      return;
    }
    await run(
      request,
      onFlyersAttached: onFlyersAttached,
      onHidden: onHidden,
      onSquared: onSquared,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    runner = null;
    shuffleRunner = null;
    flightTick.dispose();
    super.dispose();
  }
}
