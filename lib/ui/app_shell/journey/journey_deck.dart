import 'dart:math' as math;

import 'package:dominican_casino/style/journey_worlds.dart';
import 'package:dominican_casino/ui/app_shell/journey/journey_board.dart';
import 'package:dominican_casino/ui/app_shell/journey/journey_face_card.dart';
import 'package:dominican_casino/ui/home/home_card_layout.dart';
import 'package:flutter/cupertino.dart';

/// Shared stack pose for the Journey deck (peek and deal are the same object).
class JourneyDeckLayout {
  static Offset stackOffset(int visualFromBottom, int count) {
    return Offset(visualFromBottom * 2.2, -visualFromBottom * 1.6);
  }

  static double stackAngle(int visualFromBottom, int count) {
    if (count <= 1) return 0;
    return (visualFromBottom - (count - 1) / 2) * 0.012;
  }
}

/// The actual Journey deck — parks as the peek, then deals without being rebuilt.
class JourneyLiveDeck extends StatelessWidget {
  const JourneyLiveDeck({
    super.key,
    required this.dealPlan,
    required this.deckArrive,
    required this.pileDeal,
    required this.defeatedDeal,
    required this.stageSize,
    required this.pileTargets,
    required this.defeatedTargets,
    required this.pileCardSize,
    this.cardGather = 0,
    this.onTap,
    this.showLabel = true,
  });

  final List<JourneyDealSlot> dealPlan;
  final double deckArrive;
  final double pileDeal;
  final double defeatedDeal;
  /// Close path: fly every table card home to the peek (0 → 1).
  final double cardGather;
  final Size stageSize;
  final List<Offset> pileTargets;
  final List<Offset> defeatedTargets;
  final double pileCardSize;
  final VoidCallback? onTap;
  final bool showLabel;

  static const peekWidth = 96.0;
  static const peekOverflow = 40.0;
  static const peekBottom = 6.0;

  static double peekHeight() => peekWidth / homeCardAspect;

  static Offset peekCenter(Size stage) => Offset(
        -peekOverflow + peekWidth * 0.5,
        stage.height - peekBottom - peekHeight() * 0.5,
      );

  double _dealFlightAt(int planIndex) {
    final slot = dealPlan[planIndex];
    if (slot.toDefeated) {
      final di = _defeatedIndex(planIndex);
      return JourneyBoard.defeatedFlight(dealPlan, defeatedDeal, di);
    }
    final ci = _challengerIndex(planIndex);
    return JourneyBoard.challengerFlight(dealPlan, pileDeal, ci);
  }

  /// Near-simultaneous home flight with a tiny peel stagger.
  double _gatherFlightAt(int planIndex) {
    if (dealPlan.isEmpty) return cardGather;
    final stagger = (planIndex / dealPlan.length) * 0.18;
    final t = ((cardGather - stagger) / (1.0 - stagger)).clamp(0.0, 1.0);
    return t;
  }

  int _challengerIndex(int planIndex) {
    var ci = 0;
    for (var i = 0; i < planIndex; i++) {
      if (!dealPlan[i].toDefeated) ci++;
    }
    return ci;
  }

  int _defeatedIndex(int planIndex) {
    var di = 0;
    for (var i = 0; i < planIndex; i++) {
      if (dealPlan[i].toDefeated) di++;
    }
    return di;
  }

  Offset _homeFor(JourneyDealSlot slot) {
    final wi = JourneyWorld.values.indexOf(slot.world);
    return slot.toDefeated ? defeatedTargets[wi] : pileTargets[wi];
  }

  @override
  Widget build(BuildContext context) {
    if (cardGather > 0.001) {
      return _buildGather();
    }
    return _buildDeal();
  }

  Widget _buildGather() {
    final peek = peekCenter(stageSize);
    final deckCardSize = peekWidth;
    final n = dealPlan.length;

    if (n == 0) return const SizedBox.shrink();

    final arrived = <int>[
      for (var j = 0; j < n; j++)
        if (_gatherFlightAt(j) >= 0.98) j,
    ]..sort();

    final inFlight = <int>[
      for (var j = 0; j < n; j++)
        if (_gatherFlightAt(j) > 0.001 && _gatherFlightAt(j) < 0.98) j,
    ];

    final stack = <Widget>[
      for (var i = arrived.length - 1; i >= 0; i--)
        _restingCard(
          planIndex: arrived[i],
          visualFromBottom: arrived.length - 1 - i,
          count: arrived.length,
          deckOrigin: peek,
          deckCardSize: deckCardSize,
          topMost: i == 0,
        ),
      for (final planIndex in inFlight)
        _GatheringDeckCard(
          slot: dealPlan[planIndex],
          flight: _gatherFlightAt(planIndex),
          from: _homeFor(dealPlan[planIndex]),
          to: peek +
              JourneyDeckLayout.stackOffset(
                n - 1 - planIndex,
                n,
              ),
          fromSize: pileCardSize *
              (1.0 - 0.03 * dealPlan[planIndex].depthInPile),
          toSize: deckCardSize,
          angleSeed: planIndex,
        ),
    ];

    return Stack(clipBehavior: Clip.none, children: stack);
  }

  Widget _buildDeal() {
    final peek = peekCenter(stageSize);
    final table = Offset(stageSize.width * 0.5, stageSize.height * 0.46);
    final deckOrigin = Offset.lerp(peek, table, deckArrive)!;
    final deckCardSize = peekWidth * (1.0 + 0.28 * deckArrive);

    final remainingAsc = <int>[
      for (var j = 0; j < dealPlan.length; j++)
        if (_dealFlightAt(j) <= 0.001) j,
    ]..sort();

    final inFlight = <int>[
      for (var j = 0; j < dealPlan.length; j++)
        if (_dealFlightAt(j) > 0.001 && _dealFlightAt(j) < 0.98) j,
    ];

    if (remainingAsc.isEmpty && inFlight.isEmpty) {
      return const SizedBox.shrink();
    }

    final stack = <Widget>[
      // High plan indices first (bottom); plan[0] last (top / peel next).
      for (var i = remainingAsc.length - 1; i >= 0; i--)
        _restingCard(
          planIndex: remainingAsc[i],
          visualFromBottom: remainingAsc.length - 1 - i,
          count: remainingAsc.length,
          deckOrigin: deckOrigin,
          deckCardSize: deckCardSize,
          topMost: i == 0,
        ),
      if (showLabel &&
          deckArrive < 0.08 &&
          pileDeal < 0.02 &&
          remainingAsc.isNotEmpty)
        Positioned(
          left: peek.dx - peekWidth / 2 + 6,
          top: peek.dy + peekHeight() / 2 - 28,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xCC000000),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                'Journey',
                style: TextStyle(
                  color: Color(0xF0FFFFFF),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      for (final planIndex in inFlight)
        _FlyingDeckCard(
          slot: dealPlan[planIndex],
          flight: _dealFlightAt(planIndex),
          deckOrigin: deckOrigin,
          target: _homeFor(dealPlan[planIndex]),
          fromSize: deckCardSize,
          toSize: pileCardSize *
              (1.0 - 0.03 * dealPlan[planIndex].depthInPile),
          angleSeed: planIndex,
        ),
    ];

    return Stack(clipBehavior: Clip.none, children: stack);
  }

  Widget _restingCard({
    required int planIndex,
    required int visualFromBottom,
    required int count,
    required Offset deckOrigin,
    required double deckCardSize,
    required bool topMost,
  }) {
    final slot = dealPlan[planIndex];
    final offset = JourneyDeckLayout.stackOffset(visualFromBottom, count);
    final angle = JourneyDeckLayout.stackAngle(visualFromBottom, count);
    final pos = deckOrigin + offset;
    final height = deckCardSize / homeCardAspect;

    return Positioned(
      left: pos.dx - deckCardSize / 2,
      top: pos.dy - height / 2,
      width: deckCardSize,
      height: height,
      child: GestureDetector(
        onTap: topMost ? onTap : null,
        child: Transform.rotate(
          angle: angle,
          child: slot.toDefeated && slot.card != null
              ? JourneyFaceUpCard(
                  assetPath: slot.card!.assetPath,
                  world: slot.world,
                  radius: 14,
                )
              : JourneyFaceDownCard(
                  world: slot.world,
                  radius: 14,
                  showSuit: topMost,
                  shadow: topMost,
                ),
        ),
      ),
    );
  }
}

class _FlyingDeckCard extends StatelessWidget {
  const _FlyingDeckCard({
    required this.slot,
    required this.flight,
    required this.deckOrigin,
    required this.target,
    required this.fromSize,
    required this.toSize,
    required this.angleSeed,
  });

  final JourneyDealSlot slot;
  final double flight;
  final Offset deckOrigin;
  final Offset target;
  final double fromSize;
  final double toSize;
  final int angleSeed;

  @override
  Widget build(BuildContext context) {
    final t = Curves.easeOutCubic.transform(flight);
    final mid = Offset(
      (deckOrigin.dx + target.dx) / 2,
      (deckOrigin.dy < target.dy ? deckOrigin.dy : target.dy) - 52,
    );
    final pos = _quad(deckOrigin, mid, target, t);
    final size = fromSize + (toSize - fromSize) * t;
    final height = size / homeCardAspect;
    final angle = (-0.08 + (angleSeed % 4) * 0.03) * (1 - t);

    return Positioned(
      left: pos.dx - size / 2,
      top: pos.dy - height / 2,
      width: size,
      height: height,
      child: Transform.rotate(
        angle: angle,
        child: slot.toDefeated && slot.card != null
            ? JourneyFaceUpCard(
                assetPath: slot.card!.assetPath,
                world: slot.world,
                radius: 12,
              )
            : JourneyFaceDownCard(world: slot.world, radius: 12),
      ),
    );
  }

  static Offset _quad(Offset a, Offset b, Offset c, double t) {
    final u = 1 - t;
    return a * (u * u) + b * (2 * u * t) + c * (t * t);
  }
}

class _GatheringDeckCard extends StatelessWidget {
  const _GatheringDeckCard({
    required this.slot,
    required this.flight,
    required this.from,
    required this.to,
    required this.fromSize,
    required this.toSize,
    required this.angleSeed,
  });

  final JourneyDealSlot slot;
  final double flight;
  final Offset from;
  final Offset to;
  final double fromSize;
  final double toSize;
  final int angleSeed;

  @override
  Widget build(BuildContext context) {
    final t = Curves.easeInCubic.transform(flight);
    final mid = Offset(
      (from.dx + to.dx) / 2,
      math.min(from.dy, to.dy) - 36,
    );
    final pos = _quad(from, mid, to, t);
    final size = fromSize + (toSize - fromSize) * t;
    final height = size / homeCardAspect;
    final angle = (0.06 - (angleSeed % 4) * 0.02) * (1 - t);

    return Positioned(
      left: pos.dx - size / 2,
      top: pos.dy - height / 2,
      width: size,
      height: height,
      child: Transform.rotate(
        angle: angle,
        child: slot.toDefeated && slot.card != null
            ? JourneyFaceUpCard(
                assetPath: slot.card!.assetPath,
                world: slot.world,
                radius: 12,
              )
            : JourneyFaceDownCard(world: slot.world, radius: 12),
      ),
    );
  }

  static Offset _quad(Offset a, Offset b, Offset c, double t) {
    final u = 1 - t;
    return a * (u * u) + b * (2 * u * t) + c * (t * t);
  }
}
