import 'dart:developer' as developer;

import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/ui/animations/animated_move_card.dart';
import 'package:dominican_casino/ui/animations/deal_annimator.dart';
import 'package:dominican_casino/game_control/interfaces/action.dart';
import 'package:dominican_casino/game_control/interfaces/card_event.dart';
import 'package:dominican_casino/game_control/interfaces/zone.dart';
import 'package:dominican_casino/style/layouts/casino_board.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/general_game/areas/new_casino_playing_area.dart';
import 'package:dominican_casino/ui/general_game/areas/gen_player_area.dart';
import 'package:dominican_casino/ui/widgets/gen_game_control.dart';
import 'package:dominican_casino/ui/general_game/game_status_sheet.dart';
import 'package:dominican_casino/view_models/games/general_game_view_model.dart';
import 'package:flutter/cupertino.dart';
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
  bool _isAnimating = false;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryPlayEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GeneralGameViewModel>();
    if (vm.loading) {
      return CupertinoPageScaffold(
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
      );
    }

    return SizedBox(
      width: MediaQuery.of(context).size.width.clamp(0, 600),
      child: CupertinoPageScaffold(
        child: DecoratedBox(
          decoration: AppStyle.theme.tableBackground(),
          child: SafeArea(
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsetsGeometry.symmetric(vertical: 24),
                  child: CasinoBoard(child: Container()),
                ),
                Column(
                  children: [
                    const SizedBox(height: 10),

                    Expanded(
                      child: (vm.gameState.gameMode == GameMode.casinoNew)
                          ? Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: NewCasinoPlayingArea(),
                            )
                          : Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 0,
                              ),
                              child: null,
                            ),
                    ),
                    const SizedBox(height: 10),
                    GenPlayerArea(),

                    const SizedBox(height: 16),
                  ],
                ),
                DraggableScrollableSheet(
                  initialChildSize: 0.08,
                  minChildSize: 0.08,
                  maxChildSize: 0.40,
                  snap: true,
                  // expand: false,
                  snapSizes: const [0.08, .40],
                  builder: (context, scrollController) {
                    return GameStatusSheet(scrollController: scrollController);
                  },
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
      ),
    );
  }

  Future<void> _tryPlayEvents() async {
    if (!mounted || _isAnimating) return;

    final events = vm.gameState.cardMoveEvents;
    final newEvents = events
        .where((e) => !vm.lastPlayedIds.contains(e.id))
        .toList();

    if (newEvents.isEmpty) return;

    _isAnimating = true;

    for (final event in newEvents) {
      vm.lastPlayedIds.add(event.id);
      await _playEvent(event);
      vm.hiddenCardIds.remove(event.card.id);
      vm.notifyListeners();
    }

    _isAnimating = false;
  }

  Future<void> _playEvent(CardMoveEvent event) async {
    final myPid = vm.me;

    final fromKey = vm.keyForZone(event.from);
    final toKey = vm.keyForZone(event.to);

    if (toKey == null) return;
    if (fromKey == null) return;
    if (toKey.currentContext == null) return;

    await CardMoveAnimator.animateCardMove(
      context: context,
      vsync: this,
      fromKey: fromKey,
      toKey: toKey,
      beginRotation: event.performedBy == myPid ? -0.08 : 0.08,
      cardWidth: 55,
      child: AnimatedMoveCard(
        card: event.card,
        faceUp: shouldShowFrontForEvent(event),
        width: 55,
      ),
    );
  }

  bool shouldShowFrontForEvent(CardMoveEvent event) {
    final myPid = vm.me;

    // Table and stacks are always face up
    if (event.from.type == ZoneType.table ||
        event.to.type == ZoneType.table ||
        event.from.type == ZoneType.stack ||
        event.to.type == ZoneType.stack) {
      return true;
    }
    if (event.from.type == ZoneType.playerHand) {
      return true;
    }
    if (event.to.type == ZoneType.playerHand && event.to.holderId == myPid) {
      return true;
    }
    return false;
  }
}
