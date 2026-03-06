import 'dart:developer' as developer;

import 'package:dominican_casino/style/layouts/app_popup.dart';
import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/ui/game/decks/game_deck.dart';
import 'package:dominican_casino/ui/game/decks/players_deck.dart';
import 'package:dominican_casino/ui/game/popups/button_instructions.dart';
import 'package:dominican_casino/ui/game/popups/game_completed.dart';
import 'package:dominican_casino/ui/game/popups/game_status.dart';
import 'package:dominican_casino/ui/game/popups/players_deck_content.dart';
import 'package:dominican_casino/ui/game/popups/round_completed.dart';
import 'package:dominican_casino/ui/game/areas/opponent_area.dart';
import 'package:dominican_casino/ui/game/areas/player_area.dart';
import 'package:dominican_casino/ui/game/areas/playing_area.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/view_models/game_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => GameScreenState();
}

class GameScreenState extends State<GameScreen> {
  bool _disposed = false;

  @override
  void dispose() {
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
    final playerId = vm.me;

    //ENSURE INITIALIZED
    if (playerId == null) {
      return const CupertinoPageScaffold(
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    ///GAME/ROUND STATUS CONTROLLERS
    ///---------------------
    if (vm.showRoundCompletePopup) {
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

    if (vm.g?.winnerId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_disposed || !mounted) return;
        final route = ModalRoute.of(context);
        if (route != null && !route.isCurrent) return;

        showAppPopup(
          context: context,
          title: "Game Over",
          content: GameCompletedContent(vm: vm),
          primaryText: "Go to Lobby",
          onPrimary: () async => vm.endGame(),
        );
      });
    }

    return SizedBox(
      width: MediaQuery.of(context).size.width.clamp(0, 600),
      child: CupertinoPageScaffold(
        child: DecoratedBox(
          decoration: AppStyle.theme.tableBackground(),
          child: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                // Base board
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                      child: _buildGameTopBar(context, vm),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 36),
                      child: const OpponentArea(),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: PlayingArea(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    PlayerArea(),
                  ],
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: ConstrainedBox(constraints: BoxConstraints(maxWidth: 70, maxHeight: 70*1.4 ),
                  child:  AppStyle.theme.dottedBox(
                    child: PlayersDeck(cards: [], me: false, extraPoints: 0),
                  ),
                ),),
                AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  alignment: vm.controlGame
                      ? Alignment.center
                      : Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0,0,8,0),
                    child: GameControlDeck(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  // ---------------------------
  // AREAS START
  // --------------------------

  ///GAME TOP BAR
  ///---------------------

  Widget _buildGameTopBar(BuildContext context, RoomViewModel vm) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: AppStyle.theme.raisedSurfaceBox(),
      child: Row(
        children: [
          // Left: Room
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Room: ${vm.gameId ?? "-"}",
                style: AppStyle.theme.body,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // Center: Joined As
          Expanded(
            child: Center(
              child: Text(
                "You: ${vm.joinedAsPlayer}",
                style: AppStyle.theme.body,
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
                  developer.log('');
                  HapticFeedback.mediumImpact();
                  final ok = await vm.confirmDelete(context);
                  if (ok) await vm.leaveGame();

                  if (context.mounted) context.go('/lobby');
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.close, color: AppStyle.theme.danger, size: 18),
                    const SizedBox(width: 6),
                    Text("Leave", style: AppStyle.theme.body),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  ///POPUP HELPERS START
  ///--------------------

  static void showPlayersDeckPopup(
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

  static void showControlsLegendPopup(BuildContext context) {
    showAppPopup(
      context: context,
      title: "Controls",
      // subtitle: "What each button does",
      primaryText: "Got it",
      content: const ControlsLegendContent(),
    );
  }

  static void showGameStatusPopup(BuildContext context, RoomViewModel vm) {
    showAppPopup(
      context: context,
      title: 'Game Status',
      // subtitle: 'Turn, dealer, round, and scores',
      content: GameStatusContent(vm: vm),
      primaryText: 'Close',
      onPrimary: () {}, // optional
      barrierDismissible: true,
    );
  }
}
