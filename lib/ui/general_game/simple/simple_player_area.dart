import 'dart:math' as math;

import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/ui/animations/flight_aware_card.dart';
import 'package:dominican_casino/ui/cards/playing_card.dart';
import 'package:dominican_casino/ui/general_game/board_drag_handle.dart';
import 'package:dominican_casino/ui/general_game/play_action_bar.dart';
import 'package:dominican_casino/ui/tutorial/tutorial_hint_pulse.dart';
import 'package:dominican_casino/ui/widgets/winning_hand_wave.dart';
import 'package:dominican_casino/view_models/games/board_drag.dart';
import 'package:dominican_casino/view_models/games/general_game_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

/// Casino player hand: tap-select plus inline actions over a centered fan.
class SimplePlayerArea extends StatefulWidget {
  const SimplePlayerArea({super.key});

  @override
  State<SimplePlayerArea> createState() => _SimplePlayerAreaState();
}

class _SimplePlayerAreaState extends State<SimplePlayerArea> {
  double _fanGap = 48;
  static const double _cardWidth = 110.0;
  static const double _fanHeight = 168.0;
  // Reduced to keep the fan visually tighter on small screens.
  static const double _edgeAngle = 0.16;
  static const double _selectedLift = 12.0;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GeneralGameViewModel>();
    return Column(
      children: [
        PlayActionBar(vm: vm),
        const SizedBox(height: 2),
        SizedBox(
          height: _fanHeight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cards = vm.myHandCards;
              if (cards.isEmpty) return const SizedBox.shrink();
              final celebrating = vm.isCelebratingHand(vm.me);
              final count = cards.length;
              // Prefer tightening the gap first (cards closer), and only
              // shrink cards if we can't keep the minimum gap.
              const minGap = 12.0;
              const minCardWidth = 56.0;

              double cardWidth;
              double gap;
              if (count == 1) {
                cardWidth = _cardWidth;
                gap = 0.0;
              } else {
                final gapForFullCards =
                    (constraints.maxWidth - _cardWidth) / (count - 1);
                if (gapForFullCards >= minGap) {
                  cardWidth = _cardWidth;
                  gap = gapForFullCards.clamp(0.0, celebrating ? 64.0 : 56.0);
                } else {
                  // Keep a tighter gap, reduce card width to fit.
                  gap = minGap;
                  cardWidth = constraints.maxWidth - (count - 1) * gap;
                  if (cardWidth < minCardWidth) {
                    // Last resort: shrink evenly so everything fits.
                    cardWidth = constraints.maxWidth / count;
                    gap = (constraints.maxWidth - cardWidth) / (count - 1);
                  }
                }
              }

              final cardH = cardWidth * 1.4;
              _fanGap = gap;

              final totalWidth = cardWidth + ((count - 1) * gap);
              final draggingId = vm.draggingSource?.id;
              final mid = (count - 1) / 2.0;
              final baseTop = _fanHeight - cardH;

              return ListenableBuilder(
                listenable: vm.motion,
                builder: (context, _) {
                  if (vm.motion.isShuffling) return const SizedBox.shrink();
                  // Deal flights land upright; fan once every hand card has arrived.
                  final holdFlat =
                      cards.isNotEmpty &&
                      cards.every((c) => vm.motion.isInFlight(c.id));
                  return SizedBox(
                    width: constraints.maxWidth,
                    height: _fanHeight,
                    child: Center(
                      child: SizedBox(
                        key: vm.myHandKey,
                        width: totalWidth,
                        height: _fanHeight,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            for (int i = 0; i < count; i++)
                              _fanCard(
                                vm: vm,
                                card: cards[i],
                                index: i,
                                count: count,
                                mid: mid,
                                gap: gap,
                                cardWidth: cardWidth,
                                baseTop: baseTop,
                                draggingId: draggingId,
                                holdFlat: holdFlat,
                                celebrating: celebrating,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _fanCard({
    required GeneralGameViewModel vm,
    required PlayingCardModel card,
    required int index,
    required int count,
    required double mid,
    required double gap,
    required double cardWidth,
    required double baseTop,
    required String? draggingId,
    required bool holdFlat,
    required bool celebrating,
  }) {
    final selected = vm.selectedCard == card && draggingId != card.id;
    final t = count == 1 ? 0.0 : (index - mid) / mid;
    final angle = holdFlat || celebrating ? 0.0 : t * _edgeAngle;
    final arcDrop = holdFlat || celebrating ? 0.0 : t.abs() * 8;
    return AnimatedPositioned(
      key: ValueKey(card.id),
      duration: draggingId == card.id
          ? Duration.zero
          : const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      left: index * gap,
      top: baseTop + arcDrop - (selected ? _selectedLift : 0),
      child: AnimatedRotation(
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
        turns: (selected ? angle * 0.35 : angle) / (2 * math.pi),
        alignment: Alignment.bottomCenter,
        child: BoardDragHandle(
          source: BoardDragSource.hand(card),
          enabled: !vm.isAnimating && !vm.hasDropPending,
            feedbackWidth: cardWidth,
          tableFeedbackWidth: 72,
          onTap: () => vm.selectCard(card),
          onHandReorder: (global) {
            if (vm.hitTestDropTarget(global) != null) return;
            final id = vm.draggingSource?.id;
            if (id == null) return;
            final live = vm.myHandCards;
            final liveFrom = live.indexWhere((c) => c.id == id);
            if (liveFrom < 0) return;
            final to = _indexForGlobalCenter(global, live.length);
            if (to != liveFrom) vm.moveHandCardTo(liveFrom, to);
          },
          child: Opacity(
            opacity: vm.isDragHidden(card.id) ? 0 : 1,
            child: WinningHandWave(
              active: celebrating,
              index: index,
              amplitude: 4,
              child: TutorialPulse(
                cardId: card.id,
                targetKey: vm.keyForCard(card.id, CardSlot.myHand),
                child: FlightAwareCard(
                  key: vm.keyForCard(card.id, CardSlot.myHand),
                  motion: vm.motion,
                  cardId: card.id,
                      width: cardWidth,
                  child: PlayingCard(
                    playingCardModel: card,
                        width: cardWidth,
                    isSelected: selected || celebrating,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  int _indexForGlobalCenter(Offset globalCenter, int count) {
    final vm = context.read<GeneralGameViewModel>();
    final box = vm.myHandKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || count <= 0) return 0;
    final local = box.globalToLocal(globalCenter);
    if (_fanGap <= 0) return 0;
    return (local.dx / _fanGap).round().clamp(0, count - 1);
  }
}
