import 'package:dominican_casino/layouts/app_popup.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/popups/button_instructions.dart';
import 'package:dominican_casino/popups/game_completed.dart';
import 'package:dominican_casino/popups/game_status.dart';
import 'package:dominican_casino/popups/players_deck.dart';
import 'package:dominican_casino/popups/round_completed.dart';
import 'package:dominican_casino/style/theme_data.dart';
import 'package:dominican_casino/view_models/game_view_model.dart';
import 'package:dominican_casino/widgets/action_icon_button.dart';
import 'package:dominican_casino/widgets/playing_area_stack.dart';
import 'package:dominican_casino/widgets/playing_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _disposed = false;

  @override
  void disposed() {
    _disposed = true;
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoomViewModel>().startListening();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RoomViewModel>();
    final playerId = vm.playerId;

    if (playerId == null) {
      return const CupertinoPageScaffold(
        child: Center(child: CupertinoActivityIndicator()),
      );
    }
    if (vm.showRoundCompletePopup && vm.currentGame?.winnerId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_disposed || !mounted) return;

        final route = ModalRoute.of(context);
        if (route != null && !route.isCurrent) return;

        showAppPopup(
          context: context,
          title: 'Round ${vm.roundIndex} Completed',
          subtitle: 'Review scores before continuing',
          content: RoundCompletedContent(vm: vm),
          primaryText: 'Continue',
          onPrimary: () => vm.pressContinue(),
          barrierDismissible: false,
        );
      });
    }

    if (vm.currentGame?.winnerId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_disposed || !mounted) return;
        final route = ModalRoute.of(context);
        if (route != null && !route.isCurrent) return;

        showAppPopup(
          context: context,
          title: "Game Over",
          content: GameCompletedContent(vm: vm),
        );
      });
    }

    return CupertinoPageScaffold(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // _buildGameInfoRow(vm),
              _buildGameTopBar(context, vm),
              const SizedBox(height: 10),
              _buildOpponentHandPreview(vm),
              const SizedBox(height: 10),

              // Main table area (playing area) takes the most space
              Expanded(child: _buildPlayingCardsArea(vm)),

              const SizedBox(height: 10),

              // Footer: player deck + remaining deck
              _buildDeckRow(vm),
              const SizedBox(height: 10),

              // Player area: hand + controls
              _buildPlayerSection(vm),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------
  // AREAS
  // --------------------------
  Widget _buildGameTopBar(BuildContext context, RoomViewModel vm) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: AppStyles.raisedSurfaceBox(),
      child: Row(
        children: [
          // Left: Room
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Room: ${vm.gameId ?? "-"}",
                style: AppStyles.body,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // Center: Joined As
          Expanded(
            child: Center(
              child: Text(
                "You: ${vm.joinedAsPlayer}",
                style: AppStyles.body,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // Right: Leave
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () async {
                  await vm.leaveGame();
                  if (context.mounted) context.go('/lobby');
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.close, color: AppColors.accentRed, size: 18),
                    const SizedBox(width: 6),
                    Text("Leave", style: AppStyles.body),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpponentHandPreview(RoomViewModel vm) {
    // final count = vm.currentGame?.hands[vm.opponentId]?.length ?? 0;
    final countDeck = vm.currentGame?.playersDeck[vm.opponentId]?.length ?? 0;
    final isTurn = vm.currentTurn;
    final status = vm.roundStatus;

    final bothHandsEmpty = vm.handsEmpty;
    final waitingForDeal = bothHandsEmpty;
    final started =
        (vm.currentGame?.started != null && vm.currentGame!.started);
    final highlightTurn =
        (status == RoundStatus.playing &&
        !isTurn &&
        !waitingForDeal &&
        started);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlightTurn
              ? AppColors.accentGreen.withOpacity(0.75)
              : AppColors.surfaceAlt.withOpacity(0.55),
          width: highlightTurn ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Opponent's hand", style: AppStyles.muted),
          Stack(
            alignment: Alignment.centerRight,
            children: [
              if (vm.currentGame != null &&
                  vm.currentGame!.hands[vm.opponentId] != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: vm.currentGame!.hands[vm.opponentId]!
                      .map(
                        (e) => Padding(
                          padding: EdgeInsetsGeometry.symmetric(horizontal: 2),
                          child: _faceDownCardMini(),
                        ),
                      )
                      .toList(),
                ),

              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: countDeck != 0
                    ? () => showPlayersDeckPopup(
                        context,
                        vm.currentGame!.playersDeck[vm.opponentId]!,
                        me: false,
                      )
                    : null,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: AppStyles.raisedSurfaceBox(),
                  child: Column(
                    children: [
                      _faceDownCardMini(
                        height: 40,
                        width: 35,
                        hasCards: countDeck != 0,
                      ),
                      Text("$countDeck"),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayingCardsArea(RoomViewModel vm) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: AppStyles.surfaceBox(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Playing Area", style: AppStyles.title),
          const SizedBox(height: 12),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 18,
                ),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ...vm.playingAreaStacks.map((stack) {
                      bool isSelected = vm.selectedStacks.contains(stack);
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => vm.selectStack(stack),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          transform: isSelected
                              ? Matrix4.translationValues(0, -12, 0)
                              : Matrix4.identity(),
                          child: PlayingAreaStack(
                            stack: stack,
                            isSelected: isSelected,
                          ),
                        ),
                      );
                    }),

                    ...vm.playingAreaCards.map((c) {
                      bool isSelected = vm.selectedCards.contains(c);
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,

                        onTap: () => vm.selectCardToStack(c),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          transform: isSelected
                              ? Matrix4.translationValues(0, -12, 0)
                              : Matrix4.identity(),
                          child: PlayingCard(
                            playingCardModel: c,
                            isSelected: isSelected,
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerSection(RoomViewModel vm) {
    final isTurn = vm.currentTurn;
    final status = vm.roundStatus;

    final bothHandsEmpty = vm.handsEmpty; // your existing getter
    final waitingForDeal = bothHandsEmpty; // rename for clarity if you want

    String pillText;
    Color pillColor;

    if (waitingForDeal) {
      pillText = vm.isController ? "DEAL NEXT" : "WAITING DEAL";
      pillColor = AppColors.surfaceAlt;
    } else if (status == RoundStatus.playing) {
      pillText = isTurn ? "YOUR TURN" : "WAITING";
      pillColor = isTurn ? AppColors.accentGreen : AppColors.surfaceAlt;
    } else if (status == RoundStatus.completed) {
      pillText = "ROUND COMPLETE";
      pillColor = AppColors.accentRed;
    } else if (status == RoundStatus.dealing) {
      pillText = "DEALING";
      pillColor = AppColors.surfaceAlt;
    } else {
      pillText = "WAITING PLAYERS";
      pillColor = AppColors.muted;
    }

    final highlightTurn =
        (status == RoundStatus.playing && isTurn && !waitingForDeal);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlightTurn
              ? AppColors.accentGreen.withOpacity(0.75)
              : AppColors.surfaceAlt.withOpacity(0.55),
          width: highlightTurn ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPlayControls(context, vm),

          const SizedBox(height: 10),

          SizedBox(
            height: 140,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: vm.playerCards.map((c) {
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

          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text("Your Hand", style: AppStyles.title),
                  const SizedBox(width: 10),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: pillColor.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: pillColor.withOpacity(0.40)),
                    ),
                    child: Text(
                      pillText,
                      style: AppStyles.muted.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  vm.cancelSelection();
                },
                child: Icon(Icons.cancel_sharp),
              ),

              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  openGameStatusPopup(context, vm);
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
                    "My Score: ${vm.currentGame?.scores[vm.playerId] ?? 0}",
                    style: AppStyles.muted.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
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
            HapticFeedback.mediumImpact();
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
            HapticFeedback.mediumImpact();
            vm.performTakeCards();
          },
        ),
        const SizedBox(width: 10),

        ActionControlButton(
          icon: CupertinoIcons.plus_square_fill,
          label: "Add",
          enabled: vm.canAdd(),
          onTap: () {
            HapticFeedback.mediumImpact();
            vm.performStackSelectedCards();
          },
        ),
        const SizedBox(width: 10),

        ActionControlButton(
          icon: CupertinoIcons.plus_square_fill_on_square_fill,
          label: "+Pair",
          enabled: vm.canAddAndPair(),
          onTap: () {
            HapticFeedback.mediumImpact();
            vm.performStackAndPairSelectedCards();
          },
        ),
        const SizedBox(width: 10),

        ActionControlButton(
          icon: CupertinoIcons.square_fill_on_square_fill,
          label: "Pair",
          enabled: vm.canPair(),
          onTap: () {
            HapticFeedback.mediumImpact();
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        onPressed: () => showControlsLegendPopup(context),
        child: const Icon(Icons.info),
      ),
    );
  }

  Widget _buildDeckRow(RoomViewModel vm) {
    return Row(
      children: [
        Expanded(child: _buildPlayerDeckArea(vm)),
        const SizedBox(width: 10),
        Expanded(child: _buildDeckArea(vm)),
      ],
    );
  }

  Widget _buildPlayerDeckArea(RoomViewModel vm) {
    return _deckBox(
      title: "Your Deck",
      subtitle: "${vm.playerDeckCards.length} cards",
      onAction: () => showPlayersDeckPopup(context, vm.playerDeckCards),
      actionIcon: Icons.scoreboard_sharp,
      hasCards: vm.playerDeckCards.isNotEmpty,
    );
  }

  Widget _buildDeckArea(RoomViewModel vm) {
    final g = vm.currentGame;

    final remaining = g?.deck.length;
    final started = g?.started ?? false;
    final isController = vm.isController; // you already have this in vm
    final canRedeal =
        (started && isController) && (vm.canStartNextRound || vm.handsEmpty);

    // Not started: allow controller to start if hands empty (your original rule)
    final canStart =
        (vm.bothPlayersJoined && isController) &&
        ((!started) || (vm.handsEmpty));

    // Decide label/icon/handler in one place
    final String title = "Deck";
    final String subtitle = remaining == null ? "-" : "$remaining left";

    late final IconData actionIcon;
    late final String actionLabel;
    late final VoidCallback? onAction;

    if (!started) {
      if (canStart) {
        actionIcon = Icons.play_arrow_rounded;
        actionLabel = "Start";
        onAction = () => vm.startGame();
      } else {
        actionIcon = Icons.lock_outline_sharp;
        actionLabel = isController ? "Waiting…" : "Locked";
        onAction = null;
      }
    } else {
      if (canRedeal) {
        actionIcon = Icons.refresh_rounded;
        actionLabel = "Redeal";
        onAction = (vm.canStartNextRound)
            ? () => vm.startNextRound()
            : () => vm.redealSameRound();
      } else {
        actionIcon = Icons.lock_outline_sharp;
        actionLabel = isController ? "Waiting…" : "Locked";
        onAction = null;
      }
    }

    return _deckBox(
      title: title,
      subtitle: subtitle,
      actionLabel: actionLabel, // add this param if you want text
      actionIcon: actionIcon,
      onAction: onAction,
      hasCards: remaining != 0,
    );
  }

  Widget _deckBox({
    required String title,
    required String subtitle,
    required IconData actionIcon,
    String? actionLabel,
    VoidCallback? onAction,
    bool enabled = true,
    bool hasCards = false,
  }) {
    final isEnabled = enabled && onAction != null;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: isEnabled ? onAction : null,
      child: Opacity(
        opacity: isEnabled ? 1 : .35,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: AppStyles.raisedSurfaceBox(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _faceDownCardMini(width: 32, height: 44, hasCards: hasCards),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppStyles.title),
                  const SizedBox(height: 6),
                  Text(subtitle, style: AppStyles.body),
                ],
              ),
              Row(
                children: [
                  Icon(actionIcon, color: AppColors.surfaceAlt),
                  if (actionLabel != null) ...[
                    const SizedBox(width: 8),
                    // Text(actionLabel, style: AppStyles.body),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _faceDownCardMini({
    double width = 44,
    double height = 62,
    bool hasCards = true,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: AppColors.surfaceAlt.withOpacity(.7),
        border: Border.all(
          color: AppColors.surfaceAlt.withOpacity(.6),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 6,
            offset: const Offset(0, 2),
            color: Colors.black.withOpacity(.12),
          ),
        ],
      ),
      child: (hasCards)
          ? Container(
              decoration: AppStyles.surfaceBox().copyWith(
                image: DecorationImage(
                  image: AssetImage('assets/images/logo_card.png'),
                  fit: BoxFit.fitHeight,
                ),
              ),
            )
          : Container(
              decoration: AppStyles.surfaceBox(),
              child: Icon(CupertinoIcons.minus_circle_fill),
            ),
    );
  }

  void showPlayersDeckPopup(
    BuildContext context,
    List<PlayingCardModel> cards, {
    bool me = true,
  }) {
    showAppPopup(
      context: context,
      title: "${me ? "My" : "Opponent's"} Collected Cards",
      content: CollectedCardsStrip(cards: cards),
    );
  }

  void showControlsLegendPopup(BuildContext context) {
    showAppPopup(
      context: context,
      title: "Controls",
      subtitle: "What each button does",
      primaryText: "Got it",
      content: const ControlsLegendContent(),
    );
  }

  void openGameStatusPopup(BuildContext context, RoomViewModel vm) {
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
