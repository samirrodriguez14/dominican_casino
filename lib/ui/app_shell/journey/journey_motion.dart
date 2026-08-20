import 'dart:math' as math;

import 'package:dominican_casino/models/journey.dart';
import 'package:dominican_casino/style/journey_worlds.dart';
import 'package:dominican_casino/ui/home/home_card_layout.dart';
import 'package:flutter/cupertino.dart';

// ── Progress + deal plan ────────────────────────────────────────────────────

/// Progress channels for opening / closing the Journey table.
class JourneyOpenProgress {
  const JourneyOpenProgress({
    this.deckArrive = 1,
    this.deckFan = 1,
    this.sectionExpand = 1,
    this.pileDeal = 1,
    this.defeatedDeal = 1,
    this.cardGather = 0,
  });

  /// Peek → center for the real card stack.
  final double deckArrive;

  /// Stack spread: tight peek (~0.4) → fan out on open → travel to center.
  final double deckFan;

  /// Top + defeated shells expand L→R while the deck moves to center.
  final double sectionExpand;

  /// Challenger cards fly from the deck into top piles.
  final double pileDeal;

  /// Defeated cards fly from the deck into defeated piles (after challengers).
  final double defeatedDeal;

  /// Close-only: piles exit, then peek deck slides in (0 on table → 1 at peek).
  final double cardGather;

  static const settled = JourneyOpenProgress();
}

/// One card in the open-deal sequence (challengers first, defeated last / bottom).
class JourneyDealSlot {
  const JourneyDealSlot({
    required this.world,
    required this.toDefeated,
    this.card,
    this.depthInPile = 0,
  });

  final JourneyWorld world;
  final bool toDefeated;
  final JourneyCardDef? card;
  final int depthInPile;
}

/// Deal-order helpers shared by board, deck, and stage.
abstract final class JourneyDealPlan {
  static const worldCount = 4;
  static const cardsPerPile = 4;
  static const dealCardCount = worldCount * cardsPerPile;

  /// Challengers first (deck top), defeated last (deck bottom → dealt after).
  static List<JourneyDealSlot> forSnapshot(JourneyDisplaySnapshot snap) {
    final challenger = <JourneyDealSlot>[];
    final defeated = <JourneyDealSlot>[];
    for (final world in JourneyWorld.values) {
      final def = snap.worldOf(world);
      if (!def.unlocked) {
        for (var d = 0; d < cardsPerPile; d++) {
          challenger.add(
            JourneyDealSlot(world: world, toDefeated: false, depthInPile: d),
          );
        }
      } else {
        final pile = def.pileCards;
        for (var d = 0; d < pile.length; d++) {
          challenger.add(
            JourneyDealSlot(
              world: world,
              toDefeated: false,
              card: pile[d],
              depthInPile: d,
            ),
          );
        }
        final fallen = def.defeatedCards;
        for (var d = 0; d < fallen.length; d++) {
          defeated.add(
            JourneyDealSlot(
              world: world,
              toDefeated: true,
              card: fallen[d],
              depthInPile: d,
            ),
          );
        }
      }
    }
    return [...challenger, ...defeated];
  }

  static int challengerCount(List<JourneyDealSlot> plan) =>
      plan.where((s) => !s.toDefeated).length;

  static int defeatedCount(List<JourneyDealSlot> plan) =>
      plan.where((s) => s.toDefeated).length;

  static double _phaseFlight(double phase, int index, int count) {
    if (count <= 0) return 1;
    const active = 0.72;
    final slot = 1.0 / count;
    final start = index * slot;
    final end = start + slot * active;
    if (phase <= start) return 0;
    if (phase >= end) return 1;
    return ((phase - start) / (end - start)).clamp(0.0, 1.0);
  }

  static double challengerFlight(
    List<JourneyDealSlot> plan,
    double pileDeal,
    int challengerIndex,
  ) =>
      _phaseFlight(pileDeal, challengerIndex, challengerCount(plan));

  static double defeatedFlight(
    List<JourneyDealSlot> plan,
    double defeatedDeal,
    int defeatedIndex,
  ) =>
      _phaseFlight(defeatedDeal, defeatedIndex, defeatedCount(plan));

  static int challengerLandedDepth(
    List<JourneyDealSlot> plan,
    double pileDeal,
    JourneyWorld world,
  ) {
    var n = 0;
    var ci = 0;
    for (final slot in plan) {
      if (slot.toDefeated) continue;
      if (slot.world == world &&
          challengerFlight(plan, pileDeal, ci) >= 0.98) {
        n++;
      }
      ci++;
    }
    return n;
  }

  static int defeatedLandedCount(
    List<JourneyDealSlot> plan,
    double defeatedDeal,
    JourneyWorld world,
  ) {
    var n = 0;
    var di = 0;
    for (final slot in plan) {
      if (!slot.toDefeated) continue;
      if (slot.world == world &&
          defeatedFlight(plan, defeatedDeal, di) >= 0.98) {
        n++;
      }
      di++;
    }
    return n;
  }
}

// ── Timeline (swap controller → channels) ───────────────────────────────────

/// Pure mapping from swap progress (+ peek fan) into open/close channels.
///
/// Keep interval numbers here so [JourneyStage] stays orchestration-only.
abstract final class JourneyTimeline {
  static const openDuration = Duration(milliseconds: 3200);
  static const closeDuration = Duration(milliseconds: 1450);
  static const peekFanDuration = Duration(milliseconds: 320);

  /// [t] is swap controller value (0 games → 1 journey).
  /// [peekFan] is the immediate tap-fan controller (0 tight → 1 open).
  static JourneyOpenProgress openProgress({
    required double t,
    required double peekFan,
    required bool closing,
  }) {
    final closeC = (1.0 - t).clamp(0.0, 1.0);
    return JourneyOpenProgress(
      deckArrive: _deckArrive(t: t, closeC: closeC, closing: closing),
      deckFan: _deckFan(t: t, peekFan: peekFan, closing: closing),
      sectionExpand: _sectionExpand(t: t, closeC: closeC, closing: closing),
      pileDeal: closing
          ? 1.0
          : const Interval(0.38, 0.74, curve: Curves.linear).transform(t),
      defeatedDeal: closing
          ? 1.0
          : const Interval(0.72, 1.0, curve: Curves.linear).transform(t),
      cardGather: closing
          ? const Interval(0.0, 0.9, curve: Curves.linear).transform(closeC)
          : 0.0,
    );
  }

  /// 0 = games on table, 1 = eaten into Games tab.
  static double gameEat({
    required double t,
    required bool closing,
  }) {
    if (closing) {
      final closeC = (1.0 - t).clamp(0.0, 1.0);
      return 1.0 -
          const Interval(0.48, 0.78, curve: Curves.easeInOutCubic)
              .transform(closeC);
    }
    return const Interval(0.0, 0.22, curve: Curves.easeInOutCubic).transform(t);
  }

  static double gameScale({
    required double eat,
    required bool closing,
  }) {
    if (closing) {
      final show = (1.0 - eat).clamp(0.0, 1.0);
      final little = 0.05 + 0.12 * show;
      final pop = Curves.easeInCubic.transform(show);
      return little + (1.0 - little) * pop;
    }
    return math.max(0.03, 1.0 - Curves.easeInCubic.transform(eat) * 0.97);
  }

  static double _deckFan({
    required double t,
    required double peekFan,
    required bool closing,
  }) {
    if (closing) return 0.42;
    final tapFan = Curves.easeOutCubic.transform(peekFan);
    final openFan =
        const Interval(0.0, 0.14, curve: Curves.easeOutCubic).transform(t);
    return 0.38 + 1.1 * math.max(tapFan, openFan);
  }

  static double _deckArrive({
    required double t,
    required double closeC,
    required bool closing,
  }) {
    if (closing) {
      return 1.0 -
          const Interval(0.0, 0.55, curve: Curves.easeInCubic).transform(closeC);
    }
    return const Interval(0.12, 0.40, curve: Curves.easeInOutCubic)
        .transform(t);
  }

  static double _sectionExpand({
    required double t,
    required double closeC,
    required bool closing,
  }) {
    if (closing) {
      return 1.0 -
          const Interval(0.0, 0.55, curve: Curves.easeInCubic).transform(closeC);
    }
    return const Interval(0.14, 0.40, curve: Curves.easeOutCubic).transform(t);
  }
}

// ── Table geometry ──────────────────────────────────────────────────────────

/// Shared board/deck coordinates for the Journey table.
abstract final class JourneyTableLayout {
  static double pileWidth(double stageWidth) => (stageWidth - 30) / 4;

  static double pileCardSize(double stageWidth) => pileWidth(stageWidth) * 0.88;

  static List<Offset> pileTargets(Size stage) {
    final pileW = pileWidth(stage.width);
    final pileH = pileW / homeCardAspect;
    return [
      for (var i = 0; i < 4; i++)
        Offset(15 + pileW * (i + 0.5), 8 + pileH * 0.42),
    ];
  }

  static List<Offset> defeatedTargets(Size stage) {
    final pileW = pileWidth(stage.width);
    final defeatedY = stage.height * 0.88;
    return [
      for (var i = 0; i < 4; i++) Offset(15 + pileW * (i + 0.5), defeatedY),
    ];
  }

  /// Quadratic bezier used by eat/spit and card flights.
  static Offset quad(Offset a, Offset b, Offset c, double t) {
    final u = 1 - t;
    return a * (u * u) + b * (2 * u * t) + c * (t * t);
  }

  /// Lift, then dive into the Games tab (and reverse on spit).
  static Offset gameCarouselDelta({
    required double eat,
    required Size stage,
    required Offset tabCenter,
  }) {
    final origin = Offset(stage.width / 2, stage.height / 2);
    final toTab = tabCenter - origin;
    final mid = Offset(toTab.dx * 0.28, -stage.height * 0.14);
    final t = Curves.easeInOutCubic.transform(eat);
    return quad(Offset.zero, mid, toTab, t);
  }
}
