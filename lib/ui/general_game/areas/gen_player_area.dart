import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/animations/flight_aware_card.dart';
import 'package:dominican_casino/ui/cards/playing_card.dart';
import 'package:dominican_casino/ui/general_game/board_drag_handle.dart';
import 'package:dominican_casino/ui/general_game/hand_fan_layout.dart';
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
  HandFanLayout? _fanLayout;
  static const double _cardWidth = 100.0;

  @override
  Widget build(BuildContext context) {
    final highlightTurn = vm.isSeatTurn(vm.me);
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
                final layout = HandFanLayout.fit(
                  count: count,
                  maxWidth: constraints.maxWidth,
                  preferredCardWidth: _cardWidth,
                  maxGap: 72.0,
                  lockCardSize: true,
                  progressiveTighten: true,
                );
                _fanLayout = layout;
                final gap = layout.gap;
                final cardWidth = layout.cardWidth;

                final totalWidth = layout.totalWidth(count);
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
                                feedbackWidth: cardWidth,
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
                                      width: cardWidth,
                                      child: PlayingCard(
                                        playingCardModel: cards[i],
                                        width: cardWidth,
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
    final layout = _fanLayout;
    final box = _fanKey.currentContext?.findRenderObject() as RenderBox?;
    if (layout == null || box == null || !box.hasSize || count <= 0) return 0;
    final local = box.globalToLocal(globalCenter);
    return layout.indexAtLocalX(local.dx, count);
  }
}
