import 'package:dominican_casino/layouts/app_popup.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/screens/game/popups/button_instructions.dart';
import 'package:dominican_casino/screens/game/popups/game_status.dart';
import 'package:dominican_casino/screens/game/decks/players_deck.dart';
import 'package:dominican_casino/screens/game/widgets/action_icon_button.dart';
import 'package:dominican_casino/style/theme_data.dart';
import 'package:dominican_casino/view_models/game_view_model.dart';
import 'package:dominican_casino/screens/game/widgets/cards/playing_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class PlayerArea extends StatefulWidget {
  const PlayerArea({super.key});
  @override
  State<StatefulWidget> createState() => PlayerAreaState();
}

class PlayerAreaState extends State<PlayerArea> {
  RoomViewModel get vm => context.read<RoomViewModel>();

  @override
  Widget build(BuildContext context) {
    final isTurn = vm.currentTurn;
    final status = vm.roundStatus;
    final waitingForDeal = vm.handsEmpty;

    String pillText;
    Color pillColor;

    if (waitingForDeal) {
      pillText = vm.isController ? "DEAL NEXT" : "WAITING DEAL";
      pillColor = AppStyles.theme.surfaceAlt;
    } else if (status == RoundStatus.playing) {
      pillText = isTurn ? "YOUR TURN" : "WAITING";
      pillColor = isTurn ? AppColors.accentGreen : AppStyles.theme.surfaceAlt;
    } else if (status == RoundStatus.completed) {
      pillText = "ROUND COMPLETE";
      pillColor = AppColors.accentRed;
    } else if (status == RoundStatus.dealing) {
      pillText = "DEALING";
      pillColor = AppStyles.theme.surfaceAlt;
    } else {
      pillText = "WAITING PLAYERS";
      pillColor = AppStyles.theme.muted;
    }

    final highlightTurn = vm.currentTurn;
    bool opponentJoined = vm.opp != null && vm.opp != "";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: AppStyle.theme.playerSectionBox(
        highlightColor: AppColors.accentGreen,
        highlight: highlightTurn,
        joined: opponentJoined,
      ),
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Opacity(
                opacity: highlightTurn ? 1 : 0.5,
                child: _buildPlayControls(context, vm),
              ),
              const SizedBox(height: 10),
              Opacity(
                opacity: highlightTurn ? 1 : 0.5,
                child: SizedBox(
                  height: 130,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: constraints.maxWidth,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: vm.pHandCards.map((c) {
                              final isSelected = vm.selectedCard == c;

                              return Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: GestureDetector(
                                  onTap: () => vm.selectCard(c),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    transform: isSelected
                                        ? Matrix4.translationValues(0, -12, 0)
                                        : Matrix4.identity(),
                                    child: PlayingCard(
                                      playingCardModel: c,
                                      width: 80,
                                      isSelected: isSelected,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: pillColor.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: pillColor.withOpacity(0.40),
                          ),
                        ),
                        child: Text(
                          pillText,
                          style: AppStyles.theme.mutedText.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppStyles.theme.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          _showGameStatusPopup(context, vm);
                        },

                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: pillColor.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: pillColor),
                          ),
                          child: Text(
                            "My Score: ${vm.g?.scores[vm.me] ?? 0}",
                            style: AppStyles.theme.mutedText.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppStyles.theme.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: AlignmentGeometry.centerRight,
                      child: Text(''),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: PlayersDeck(
              cards: vm.pCollectedCards,
              me: true,
              extraPoints: vm.myExtraPoints,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayControls(BuildContext context, RoomViewModel vm) {
    return Row(
      children: [
        ActionControlButton(
          icon: CupertinoIcons.square_arrow_up_fill,
          label: "Play",
          enabled: vm.canPlay(),
          onTap: () {
            vm.performPlayOnTable();
          },
        ),
        const SizedBox(width: 10),

        ActionControlButton(
          icon: (vm.selectedCards.length > 1 && vm.canTake())
              ? CupertinoIcons.square_arrow_down_on_square_fill
              : CupertinoIcons.square_arrow_down_fill,
          label: (vm.selectedCards.length > 1 && vm.canTake())
              ? "+Take"
              : "Take",
          enabled: vm.canTake(),
          onTap: () {
            vm.performTakeCards();
          },
        ),
        const SizedBox(width: 10),

        ActionControlButton(
          icon: CupertinoIcons.plus_square_fill,
          label: "Add",
          enabled: vm.canAdd(),
          onTap: () {
            vm.performStackSelectedCards();
          },
        ),
        const SizedBox(width: 10),

        ActionControlButton(
          icon: CupertinoIcons.plus_square_fill_on_square_fill,
          label: "+Pair",
          enabled: vm.canAddAndPair(),
          onTap: () {
            vm.performStackAndPairSelectedCards();
          },
        ),
        const SizedBox(width: 10),

        ActionControlButton(
          icon: CupertinoIcons.square_fill_on_square_fill,
          label: "Pair",
          enabled: vm.canPair(),
          onTap: () {
            vm.performPairSelectedCards();
          },
        ),

        const SizedBox(width: 10),
        _buildControlsInfoButton(context),
      ],
    );
  }

  Widget _buildControlsInfoButton(BuildContext context) {
    return SizedBox(
      width: 42,
      height: 42,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        color: AppStyles.theme.surface,
        borderRadius: BorderRadius.circular(12),
        onPressed: () => _showControlsLegendPopup(context),
        child: const Icon(CupertinoIcons.info),
      ),
    );
  }

  void _showControlsLegendPopup(BuildContext context) {
    showAppPopup(
      context: context,
      title: "Controls",
      subtitle: "What each button does",
      primaryText: "Got it",
      content: const ControlsLegendContent(),
    );
  }

  void _showGameStatusPopup(BuildContext context, RoomViewModel vm) {
    showAppPopup(
      context: context,
      title: 'Game Status',
      subtitle: 'Turn, dealer, round, and scores',
      content: GameStatusContent(vm: vm),
      primaryText: 'Close',
      onPrimary: () {}, // optional
      barrierDismissible: true,
    );
  }
}
