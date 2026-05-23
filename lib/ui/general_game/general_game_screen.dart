import 'dart:developer' as developer;

import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/style/layouts/app_popup.dart';
import 'package:dominican_casino/game_control/interfaces/action.dart';
import 'package:dominican_casino/style/layouts/casino_board.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/general_game/areas/new_casino_playing_area.dart';
import 'package:dominican_casino/ui/general_game/areas/gen_player_area.dart';
import 'package:dominican_casino/ui/general_game/areas/new_tresydos_playing_area.dart';
import 'package:dominican_casino/ui/general_game/game_info_sheet.dart';
import 'package:dominican_casino/ui/general_game/gen_game_control.dart';
import 'package:dominican_casino/ui/general_game/game_status_sheet.dart';
import 'package:dominican_casino/view_models/games/general_game_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class GeneralGameScreen extends StatefulWidget {
  const GeneralGameScreen({super.key});

  @override
  State<GeneralGameScreen> createState() => GeneralGameScreenState();
}

class GeneralGameScreenState extends State<GeneralGameScreen>
    with TickerProviderStateMixin {
  GeneralGameViewModel get vm => context.read<GeneralGameViewModel>();
  GeneralGameViewModel? _boundVm;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final initvm = context.read<GeneralGameViewModel>();
      final ok = await initvm.loadGame();
      if (ok && mounted) {
        await initvm.joinGame();
        initvm.gameRepo.listenToGame(initvm.gid);
        return;
      }
      if (mounted) context.go('/home');
      developer.log("GameScreenInit: $ok");
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final newVm = context.read<GeneralGameViewModel>();
    if (_boundVm != newVm) {
      _boundVm?.removeListener(_onVmChanged);
      _boundVm = newVm;
      _boundVm?.addListener(_onVmChanged);
    }
  }

  void _onVmChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (vm.gameState.gameStatus == .gameOver ||
          (vm.gameState.gameStatus == .inProgress &&
              vm.gameState.round.roundStatus == .completed)) {
        showAppPopup(
          context: context,
          title: "Game Over",
          content: GameStatusSheet(vm: vm),
        );
      }
      // await _tryPlayEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GeneralGameViewModel>();
    if (vm.loading) {
      return CupertinoPageScaffold(
        child: SafeArea(
          // top: false,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CupertinoActivityIndicator(),
                Text("taking too long?"),
                CupertinoButton(
                  child: Text("Home"),
                  onPressed: () {
                    context.go('/landing');
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: MediaQuery.of(context).size.width.clamp(0, 600),
      child: CupertinoPageScaffold(
        child: DecoratedBox(
          decoration: AppStyle.theme.tableBackground(),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsetsGeometry.symmetric(vertical: 48),
                child: CasinoBoard(child: Container()),
              ),
              Column(
                children: [
                  const SizedBox(height: 40),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: _selectPlayingArea(vm.gameState.gameMode),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GenPlayerArea(),
                  const SizedBox(height: 10),

                  _buildGameTopBar(context, vm),
                  const SizedBox(height: 24),
                ],
              ),
              AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                alignment: vm.inGameAction != InGameAction.noAction
                    ? Alignment.center
                    : Alignment.centerRight,

                child: Padding(
                  padding: EdgeInsetsGeometry.only(right: 18),
                  child: GenGameControl(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _selectPlayingArea(GameMode mode) {
    switch (mode) {
      case GameMode.tresydos:
        return NewTresydosPlayingArea();
      case GameMode.casino:
        return NewCasinoPlayingArea();
      case GameMode.robaito:
    }
    return null;
  }

  Widget _buildGameTopBar(BuildContext context, GeneralGameViewModel vm) {
    return Row(
      mainAxisAlignment: .center,
      spacing: 10,
      children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            vm.sortHandCards();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: AppStyle.theme.raisedSurfaceBox(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Center: Joined As
                Icon(
                  CupertinoIcons.arrow_up_arrow_down,
                  color: AppStyle.theme.cardBorder,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            showAppPopup(
              context: context,
              title: "Game Info",
              content: GameInfoSheet(vm: vm),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: AppStyle.theme.raisedSurfaceBox(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Center: Joined As
                Icon(
                  CupertinoIcons.info,
                  color: AppStyle.theme.cardBorder,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            showAppPopup(
              context: context,
              title: "Chat",
              content: Text("Coming soon...."),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: AppStyle.theme.raisedSurfaceBox(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Center: Joined As
                Icon(
                  CupertinoIcons.chat_bubble,
                  color: AppStyle.theme.cardBorder,
                  size: 18,
                ),
              ],
            ),
          ),
        ),

        GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            showAppPopup(
              context: context,
              title: "Game Status",
              content: GameStatusSheet(vm: vm),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: AppStyle.theme.raisedSurfaceBox(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Center: Joined As
                Icon(
                  Icons.keyboard_control_key_sharp,
                  color: AppStyle.theme.cardBorder,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
