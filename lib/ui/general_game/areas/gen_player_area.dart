import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/animations/flight_aware_card.dart';
import 'package:dominican_casino/ui/cards/playing_card.dart';
import 'package:dominican_casino/ui/general_game/board_drag_handle.dart';
import 'package:dominican_casino/ui/general_game/play_action_bar.dart';
import 'package:dominican_casino/view_models/games/board_drag.dart';
import 'package:dominican_casino/view_models/games/general_game_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class GenPlayerArea extends StatefulWidget {
  const GenPlayerArea({super.key});
  @override
  State<StatefulWidget> createState() => GenPlayerAreaState();
}

class GenPlayerAreaState extends State<GenPlayerArea> {
  GeneralGameViewModel get vm => context.watch<GeneralGameViewModel>();

  final GlobalKey _fanKey = GlobalKey();
  double _fanGap = 50;
  static const double _cardWidth = 100.0;

  @override
  Widget build(BuildContext context) {
    final highlightTurn = vm.canPlayTurn;
    return Container(
      key: vm.myHandKey,
      decoration: AppStyle.theme.playerSectionBox(
        highlightColor: AppStyle.theme.turnHighlight,
        highlight: highlightTurn,
        joined: false,
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PlayActionBar(vm: vm),
          const SizedBox(height: 10),
          SizedBox(
            height: 150,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cards = vm.myHandCards;
                const selectedLift = 12.0;
                if (cards.isEmpty) return const SizedBox.shrink();
                final count = cards.length;
                const idealGap = 12.0;
                final idealTotalWidth =
                    (count * _cardWidth) + ((count - 1) * idealGap);

                double gap;
                if (idealTotalWidth <= 1200) {
                  gap = count == 1
                      ? 0
                      : (constraints.maxWidth - (count * _cardWidth)) /
                            (count - 1);
                } else {
                  gap = (constraints.maxWidth - _cardWidth) / (count - 1);
                }
                gap = gap.clamp(50.0, 80);
                _fanGap = gap;

                final totalWidth = _cardWidth + ((count - 1) * gap);
                final draggingId = vm.draggingSource?.id;

                return SizedBox(
                  width: constraints.maxWidth,
                  height: 150,
                  child: Center(
                    child: SizedBox(
                      key: _fanKey,
                      width: totalWidth,
                      height: 150,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          for (int i = 0; i < count; i++)
                            AnimatedPositioned(
                              key: ValueKey(cards[i].id),
                              duration: draggingId == cards[i].id
                                  ? Duration.zero
                                  : const Duration(milliseconds: 280),
                              curve: Curves.easeOutCubic,
                              left: i * gap,
                              top:
                                  vm.selectedCard == cards[i] &&
                                      draggingId != cards[i].id
                                  ? 0
                                  : selectedLift,
                              child: BoardDragHandle(
                                source: BoardDragSource.hand(cards[i]),
                                enabled: !vm.isAnimating && !vm.hasDropPending,
                                feedbackWidth: _cardWidth,
                                tableFeedbackWidth: 60,
                                onTap: () => vm.selectCard(cards[i]),
                                onHandReorder: (global) {
                                  if (vm.hitTestDropTarget(global) != null) {
                                    return;
                                  }
                                  final id = vm.draggingSource?.id;
                                  if (id == null) return;
                                  final live = vm.myHandCards;
                                  final liveFrom =
                                      live.indexWhere((c) => c.id == id);
                                  if (liveFrom < 0) return;
                                  final to = _indexForGlobalCenter(
                                    global,
                                    live.length,
                                  );
                                  if (to != liveFrom) {
                                    vm.moveHandCardTo(liveFrom, to);
                                  }
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  transform:
                                      vm.selectedCard == cards[i] &&
                                          draggingId != cards[i].id
                                      ? Matrix4.translationValues(0, -12, 0)
                                      : Matrix4.identity(),
                                  child: Opacity(
                                    opacity: vm.isDragHidden(cards[i].id)
                                        ? 0
                                        : 1,
                                    child: FlightAwareCard(
                                      key: vm.keyForCard(
                                        cards[i].id,
                                        CardSlot.myHand,
                                      ),
                                      motion: vm.motion,
                                      cardId: cards[i].id,
                                      width: _cardWidth,
                                      child: PlayingCard(
                                        playingCardModel: cards[i],
                                        width: _cardWidth,
                                        isSelected:
                                            vm.cardSelection.selectedCard ==
                                                cards[i] &&
                                            draggingId != cards[i].id,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  int _indexForGlobalCenter(Offset globalCenter, int count) {
    final box = _fanKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || count <= 0) return 0;
    final local = box.globalToLocal(globalCenter);
    if (_fanGap <= 0) return 0;
    return (local.dx / _fanGap).round().clamp(0, count - 1);
  }
}
