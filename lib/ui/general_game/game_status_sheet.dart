import 'dart:math' as math;

import 'package:dominican_casino/game_control/game_registry.dart';
import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/services/haptics.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/style/journey_worlds.dart';
import 'package:dominican_casino/ui/app_shell/games/game_mode_how_to_overlay.dart';
import 'package:dominican_casino/ui/general_game/leave_match_to_home.dart';
import 'package:dominican_casino/ui/general_game/match_coin_payout.dart';
import 'package:dominican_casino/ui/widgets/coin_icon.dart';
import 'package:dominican_casino/ui/widgets/player_avatar.dart';
import 'package:dominican_casino/ui/widgets/player_score_avatar.dart';
import 'package:dominican_casino/view_models/games/general_game_view_model.dart';
import 'package:flutter/cupertino.dart';

Future<void> showGameStatusPopup(
  BuildContext context, {
  GeneralGameViewModel? vm,
  GameState? gameState,
  String? playerId,
  bool showActions = true,
  String? title,
  String? subtitle,
  String? primaryText,
  VoidCallback? onPrimary,
  bool barrierDismissible = true,
  bool revealLastRound = false,
}) {
  final state = gameState ?? vm?.gameState;
  final resolvedTitle =
      title ?? (state?.gameStatus == GameStatus.gameOver ? 'Game Over' : null);

  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: 'Dismiss game status',
    barrierColor: const Color(0xCC070605),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (ctx, animation, secondary) {
      return SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: SingleChildScrollView(
                child: DefaultTextStyle(
                  style: AppStyle.theme.body,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (resolvedTitle != null) ...[
                        Text(
                          resolvedTitle,
                          textAlign: TextAlign.center,
                          style: AppStyle.theme.title.copyWith(
                            color: const Color(0xFFF7F4EC),
                            fontSize: 20,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            textAlign: TextAlign.center,
                            style: AppStyle.theme.caption.copyWith(
                              color: const Color(0xCCF7F4EC),
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                      ],
                      GameStatusSheet(
                        vm: vm,
                        gameState: gameState,
                        playerId: playerId,
                        showActions: showActions,
                        revealLastRound: revealLastRound,
                      ),
                      if (primaryText != null) ...[
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: CupertinoButton.filled(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            onPressed: SoundService.wrapTap(() {
                              AppHaptics.mediumImpact();
                              Navigator.of(ctx).pop();
                              onPrimary?.call();
                            }),
                            child: Text(primaryText),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (ctx, animation, secondary, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class GameStatusSheet extends StatefulWidget {
  const GameStatusSheet({
    super.key,
    this.vm,
    this.gameState,
    this.playerId,
    this.scrollController,
    this.showActions,
    this.revealLastRound = false,
  }) : assert(vm != null || (gameState != null && playerId != null));

  final GeneralGameViewModel? vm;
  final GameState? gameState;
  final String? playerId;
  final ScrollController? scrollController;
  final bool? showActions;
  final bool revealLastRound;

  @override
  State<GameStatusSheet> createState() => _GameStatusSheetState();
}

class _GameStatusSheetState extends State<GameStatusSheet> {
  GameState get gameState => widget.vm?.gameState ?? widget.gameState!;
  String get playerId => widget.vm?.player.id ?? widget.playerId!;
  bool get showActions => widget.showActions ?? widget.vm != null;

  @override
  void initState() {
    super.initState();
    widget.vm?.addListener(_onVm);
  }

  @override
  void didUpdateWidget(covariant GameStatusSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vm != widget.vm) {
      oldWidget.vm?.removeListener(_onVm);
      widget.vm?.addListener(_onVm);
    }
  }

  @override
  void dispose() {
    widget.vm?.removeListener(_onVm);
    super.dispose();
  }

  void _onVm() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    final playerIds = gameState.playersInfo.keys.toList();
    final totalScores = gameState.scores;
    final roundScores = gameState.round.roundScores;
    final hasRound = roundScores.isNotEmpty;
    final l10n = AppLocalizations.of(context);
    final gameOver = gameState.gameStatus == GameStatus.gameOver;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420, maxHeight: 580),
      child: SingleChildScrollView(
        controller: widget.scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ScoreBoardStack(
              hasRound: hasRound,
              boards: [
                if (playerIds.isEmpty)
                  const _BoardSpec(
                    id: 'waiting',
                    name: 'Waiting',
                    avatarId: null,
                    avatarAsset: null,
                    defeatedAces: {},
                    wearJourneyAccessories: true,
                    score: 0,
                    pendingCoins: 0,
                    roundCoins: 0,
                    showMatchCoins: false,
                    beforeScore: 0,
                    roundScore: 0,
                    isDealer: false,
                    isCasino: false,
                    scoreMap: {},
                  )
                else
                  for (final pid in playerIds)
                    _BoardSpec(
                      id: pid,
                      name: _playerLabel(pid),
                      avatarId: _playerSeatLook(pid).avatarId,
                      avatarAsset: _playerSeatLook(pid).avatarAsset,
                      defeatedAces: _playerSeatLook(pid).defeatedAces,
                      wearJourneyAccessories:
                          _playerSeatLook(pid).wearJourneyAccessories,
                      score: totalScores[pid] ?? 0,
                      pendingCoins: gameOver
                          ? gameState.winPotCoins(pid) +
                              gameState.pendingCoinsFor(pid)
                          : gameState.pendingCoinsFor(pid),
                      roundCoins: _scoreN(
                        Map<String, dynamic>.from(roundScores[pid] ?? {}),
                        'coins',
                      ),
                      showMatchCoins: gameOver,
                      beforeScore: _beforeScore(
                        totalScores[pid] ?? 0,
                        roundScores[pid],
                      ),
                      roundScore: _scoreN(
                        Map<String, dynamic>.from(roundScores[pid] ?? {}),
                        'total',
                      ),
                      isDealer: gameState.controllerId == pid,
                      isCasino: GameRegistry.isCasinoFamily(gameState.gameMode),
                      place: gameOver ? gameState.finishRank(pid) : null,
                      placeLabel: gameOver &&
                              gameState.finishRank(pid) != null
                          ? l10n.coinPayoutPlace(gameState.finishRank(pid)!)
                          : null,
                      scoreMap: Map<String, dynamic>.from(
                        roundScores[pid] ?? {},
                      ),
                    ),
              ],
              locked: gameState.gameStatus == GameStatus.gameOver,
              initialFrontId: _leaderId(playerIds),
              autoReveal: widget.revealLastRound,
            ),
            if (vm != null && gameState.gameStatus == GameStatus.gameOver)
              MatchCoinPayout(vm: vm),
            if (showActions && vm != null) ...[
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _StatusIconButton(
                    icon: CupertinoIcons.info,
                    onPressed: () => _openRules(context, vm),
                  ),
                  const SizedBox(width: 8),
                  _StatusHomeButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await leaveMatchToHome(context, vm);
                    },
                  ),
                  const SizedBox(width: 8),
                  _StatusIconButton(
                    icon: CupertinoIcons.arrow_right_square_fill,
                    danger: true,
                    onPressed: () => _handleResign(context, vm),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  int _beforeScore(dynamic current, dynamic roundRaw) {
    final total = current is num ? current.toInt() : 0;
    final roundMap = roundRaw is Map
        ? Map<String, dynamic>.from(roundRaw)
        : <String, dynamic>{};
    final round = _scoreN(roundMap, 'total');
    return (total - round).clamp(0, 999);
  }

  String _leaderId(List<String> playerIds) {
    if (playerIds.isEmpty) return 'waiting';
    final winner = gameState.winnerId;
    if (gameState.gameStatus == GameStatus.gameOver &&
        winner != null &&
        winner.isNotEmpty &&
        playerIds.contains(winner)) {
      return winner;
    }
    String best = playerIds.first;
    var bestRound = _playerRoundTotal(best);
    var bestTotal = _playerTotal(best);
    for (final pid in playerIds.skip(1)) {
      final round = _playerRoundTotal(pid);
      final total = _playerTotal(pid);
      if (round > bestRound || (round == bestRound && total > bestTotal)) {
        best = pid;
        bestRound = round;
        bestTotal = total;
      }
    }
    return best;
  }

  int _playerTotal(String pid) {
    final raw = gameState.scores[pid];
    return raw is num ? raw.toInt() : 0;
  }

  int _playerRoundTotal(String pid) {
    return _scoreN(
      Map<String, dynamic>.from(gameState.round.roundScores[pid] ?? {}),
      'total',
    );
  }

  GameSeatLook _playerSeatLook(String pid) {
    final vm = widget.vm;
    if (vm != null) return vm.seatLook(pid);
    final raw = gameState.playersInfo[pid];
    if (raw is Map) {
      return GameSeatLook.fromMap(Map<String, dynamic>.from(raw));
    }
    return const GameSeatLook();
  }

  String _playerLabel(String pid) {
    if (pid == playerId) return 'You';
    final info = Map<String, dynamic>.from(
      gameState.playersInfo[pid] ?? <String, dynamic>{},
    );
    return (info['name'] as String?) ?? pid;
  }

  int _scoreN(Map<String, dynamic> map, String key) =>
      (map[key] as num?)?.toInt() ?? 0;

  void _openRules(BuildContext context, GeneralGameViewModel vm) {
    final width = MediaQuery.sizeOf(context).width;
    final cardWidth = (width * 0.62).clamp(196.0, 260.0);
    showGameModeHowTo(
      context,
      vm.gameState.gameMode,
      cardWidth: cardWidth,
      showPlay: false,
    );
  }

  Future<void> _handleResign(
    BuildContext context,
    GeneralGameViewModel vm,
  ) async {
    final shouldLeave = vm.opp == null
        ? await _confirmExitEmptyGame(context)
        : await _confirmResignGame(context);
    if (shouldLeave != true || !context.mounted) return;
    await vm.resign();
    if (!context.mounted) return;
    Navigator.of(context).pop();
    await leaveMatchToHome(context, vm);
  }

  Future<bool?> _confirmResignGame(BuildContext context) {
    return showCupertinoDialog<bool>(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('Resign?'),
          content: const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('Your opponent wins this match.'),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: SoundService.wrapTap(
                () => Navigator.of(context).pop(false),
              ),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: SoundService.wrapTap(
                () => Navigator.of(context).pop(true),
              ),
              child: const Text('Resign'),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _confirmExitEmptyGame(BuildContext context) {
    return showCupertinoDialog<bool>(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('Exit game?'),
          content: const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('This will delete the current game.'),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: SoundService.wrapTap(
                () => Navigator.of(context).pop(false),
              ),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: SoundService.wrapTap(
                () => Navigator.of(context).pop(true),
              ),
              child: const Text('Exit'),
            ),
          ],
        );
      },
    );
  }
}

class _BoardSpec {
  const _BoardSpec({
    required this.id,
    required this.name,
    required this.avatarId,
    required this.avatarAsset,
    required this.defeatedAces,
    required this.wearJourneyAccessories,
    required this.score,
    required this.pendingCoins,
    required this.roundCoins,
    required this.showMatchCoins,
    required this.beforeScore,
    required this.roundScore,
    required this.isDealer,
    required this.isCasino,
    required this.scoreMap,
    this.place,
    this.placeLabel,
  });

  final String id;
  final String name;
  final String? avatarId;
  final String? avatarAsset;
  final Set<JourneyWorld> defeatedAces;
  final bool wearJourneyAccessories;
  final dynamic score;
  final int pendingCoins;
  final int roundCoins;
  final bool showMatchCoins;
  final int beforeScore;
  final int roundScore;
  final bool isDealer;
  final bool isCasino;
  final int? place;
  final String? placeLabel;
  final Map<String, dynamic> scoreMap;

  bool get isFirst => place == 1;
  bool get isSecond => place == 2;
  bool get hasPlace => place != null && place! > 0;
}

class _ScoreBoardStack extends StatefulWidget {
  const _ScoreBoardStack({
    required this.boards,
    required this.locked,
    required this.initialFrontId,
    required this.hasRound,
    this.autoReveal = false,
  });

  final List<_BoardSpec> boards;
  final bool locked;
  final String initialFrontId;
  final bool hasRound;
  final bool autoReveal;

  @override
  State<_ScoreBoardStack> createState() => _ScoreBoardStackState();
}

class _ScoreBoardStackState extends State<_ScoreBoardStack> {
  late String _frontId;
  final Set<String> _countedIds = {};
  bool _flipToFront = false;

  bool get _revealBusy => widget.autoReveal && !_flipToFront;

  @override
  void initState() {
    super.initState();
    _frontId = widget.initialFrontId;
  }

  @override
  void didUpdateWidget(covariant _ScoreBoardStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.locked) {
      _frontId = widget.initialFrontId;
    } else if (widget.boards.every((b) => b.id != _frontId)) {
      _frontId = widget.initialFrontId;
    }
  }

  void _onBoardCounted(String id) {
    if (!widget.autoReveal || _flipToFront) return;
    if (!_countedIds.add(id)) return;
    if (_countedIds.length < widget.boards.length) return;
    Future<void>.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted || _flipToFront) return;
      setState(() => _flipToFront = true);
    });
  }

  void _promote(String id) {
    if (widget.locked || _revealBusy || id == _frontId) return;
    AppHaptics.selectionClick();
    SoundService.instance.playLayered(GameSound.softCard, volume: 0.45);
    setState(() => _frontId = id);
  }

  void _cycle(int direction) {
    if (widget.locked || _revealBusy) return;
    final ids = widget.boards.map((b) => b.id).toList();
    if (ids.length < 2) return;
    final i = ids.indexOf(_frontId);
    if (i < 0) return;
    _promote(ids[(i + direction + ids.length) % ids.length]);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.boards.isEmpty) return const SizedBox.shrink();

    final theme = AppStyle.theme;
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final boards = widget.boards;
            final count = boards.length;
            final cardW = switch (count) {
              1 => (constraints.maxWidth * 0.68).clamp(188.0, 248.0),
              2 => (constraints.maxWidth * 0.58).clamp(148.0, 216.0),
              3 => (constraints.maxWidth * 0.40).clamp(118.0, 162.0),
              _ => (constraints.maxWidth * 0.30).clamp(96.0, 132.0),
            };
            final cardH = cardW * 3.5 / 2.5;
            final edgeAngle = count >= 4 ? 0.10 : count == 3 ? 0.12 : 0.15;
            final frontLift = count >= 3 ? 10.0 : 18.0;
            final arcDropMax = count >= 4 ? 10.0 : count == 3 ? 14.0 : 14.0;
            final maxGap = switch (count) {
              2 => cardW * 0.64,
              3 => cardW * 0.78,
              _ => cardW * 0.92,
            };
            final minGap = switch (count) {
              2 => cardW * 0.48,
              3 => cardW * 0.58,
              _ => cardW * 0.70,
            };
            final gap = count == 1
                ? 0.0
                : ((constraints.maxWidth - cardW) / (count - 1)).clamp(
                    minGap,
                    maxGap,
                  );
            final totalWidth = cardW + (count - 1) * gap;
            final mid = (count - 1) / 2.0;
            final extraLift = widget.locked && boards.any((b) => b.isFirst)
                ? cardH * 0.10
                : 0.0;
            final fanHeight = cardH + frontLift + arcDropMax + extraLift;
            final paintOrder = [
              ...boards.where((b) => b.id != _frontId),
              ...boards.where((b) => b.id == _frontId),
            ];

            return GestureDetector(
              onHorizontalDragEnd: widget.locked || _revealBusy || count < 2
                  ? null
                  : (details) {
                      final v = details.primaryVelocity ?? 0;
                      if (v.abs() < 220) return;
                      _cycle(v < 0 ? 1 : -1);
                    },
              child: SizedBox(
                height: fanHeight,
                width: constraints.maxWidth,
                child: Center(
                  child: SizedBox(
                    width: totalWidth,
                    height: fanHeight,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        for (final board in paintOrder)
                          _fanBoard(
                            board: board,
                            index: boards.indexWhere((b) => b.id == board.id),
                            count: count,
                            mid: mid,
                            gap: gap,
                            cardW: cardW,
                            edgeAngle: edgeAngle,
                            frontLift: frontLift,
                            arcDropMax: arcDropMax,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          _hint(),
          textAlign: TextAlign.center,
          style: theme.caption.copyWith(
            color: theme.muted.withValues(alpha: 0.9),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  String _hint() {
    if (!widget.hasRound) return 'No round scores yet';
    if (_revealBusy) return 'Counting last round';
    if (widget.locked || widget.boards.length < 2) {
      return 'Tap a card for last round';
    }
    return 'Tap a card to bring it forward';
  }

  Widget _fanBoard({
    required _BoardSpec board,
    required int index,
    required int count,
    required double mid,
    required double gap,
    required double cardW,
    required double edgeAngle,
    required double frontLift,
    required double arcDropMax,
  }) {
    final isFront = board.id == _frontId;
    final t = count == 1 ? 0.0 : (index - mid) / mid;
    final angle = t * edgeAngle;
    final arcDrop = t.abs() * arcDropMax;
    final place = board.place;
    final scale = widget.locked && place != null
        ? (place == 1
            ? 1.10
            : place == 2
            ? 1.02
            : 0.90)
        : (isFront ? 1.0 : 0.92);
    final lift = widget.locked
        ? (place == 1
            ? frontLift + 4
            : place == 2
            ? frontLift * 0.45
            : 0.0)
        : (isFront ? frontLift : 0);
    return AnimatedPositioned(
      key: ValueKey(board.id),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      left: index * gap,
      top: frontLift + arcDrop - lift,
      width: cardW,
      child: AnimatedRotation(
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
        turns: (isFront ? angle * 0.35 : angle) / (2 * math.pi),
        alignment: Alignment.bottomCenter,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          scale: scale,
          alignment: Alignment.bottomCenter,
          child: _AvatarFlipBoard(
            spec: board,
            isFront: isFront,
            allowPromote: !widget.locked && !_revealBusy,
            onPromote: () => _promote(board.id),
            autoReveal: widget.autoReveal,
            requestFlip: _flipToFront,
            onCountingDone: () => _onBoardCounted(board.id),
          ),
        ),
      ),
    );
  }
}

class _AvatarFlipBoard extends StatefulWidget {
  const _AvatarFlipBoard({
    required this.spec,
    required this.isFront,
    this.allowPromote = false,
    this.onPromote,
    this.autoReveal = false,
    this.requestFlip = false,
    this.onCountingDone,
  });

  final _BoardSpec spec;
  final bool isFront;
  final bool allowPromote;
  final VoidCallback? onPromote;
  final bool autoReveal;
  final bool requestFlip;
  final VoidCallback? onCountingDone;

  @override
  State<_AvatarFlipBoard> createState() => _AvatarFlipBoardState();
}

class _AvatarFlipBoardState extends State<_AvatarFlipBoard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flip;
  bool _revealBusy = false;
  bool _revealDone = false;

  @override
  void initState() {
    super.initState();
    _revealBusy = widget.autoReveal;
    _flip = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
      value: widget.autoReveal ? 1 : 0,
    );
  }

  @override
  void didUpdateWidget(covariant _AvatarFlipBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.requestFlip && !oldWidget.requestFlip) {
      _flipToFront();
    }
  }

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_revealBusy) return;
    AppHaptics.lightImpact();
    SoundService.instance.playLayered(GameSound.softCard, volume: 0.55);
    if (_flip.status == AnimationStatus.completed || _flip.value > 0.5) {
      _flip.reverse();
    } else {
      _flip.forward();
    }
  }

  void _onTap() {
    if (_revealBusy) return;
    if (!widget.isFront && widget.allowPromote) {
      widget.onPromote?.call();
      return;
    }
    _toggle();
  }

  bool _counted = false;

  void _onCountingDone() {
    if (_counted) return;
    _counted = true;
    widget.onCountingDone?.call();
  }

  void _flipToFront() {
    if (!mounted || _revealDone) return;
    _revealDone = true;
    AppHaptics.lightImpact();
    SoundService.instance.playLayered(GameSound.softCard, volume: 0.55);
    _flip.reverse().whenComplete(() {
      if (mounted) setState(() => _revealBusy = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final spec = widget.spec;
    final theme = AvatarScoreTheme.of(spec.avatarId);
    return GestureDetector(
      onTap: _onTap,
      child: AspectRatio(
        aspectRatio: 2.5 / 3.5,
        child: AnimatedBuilder(
          animation: _flip,
          builder: (context, _) {
            final angle = _flip.value * math.pi;
            final showBack = angle > math.pi / 2;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0014)
                ..rotateY(angle),
              child: showBack
                  ? Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.rotationY(math.pi),
                      child: _ScoreBoardBack(
                        key: ValueKey('last-${spec.id}'),
                        theme: theme,
                        avatarId: spec.avatarId,
                        avatarAsset: spec.avatarAsset,
                        defeatedAces: spec.defeatedAces,
                        wearJourneyAccessories: spec.wearJourneyAccessories,
                        isCasino: spec.isCasino,
                        scoreMap: spec.scoreMap,
                        matchCoins: spec.pendingCoins,
                        showMatchCoins: spec.showMatchCoins,
                        raised: widget.isFront,
                        place: spec.place,
                        placeLabel: spec.placeLabel,
                        playReveal: widget.autoReveal && !_revealDone,
                        onRevealDone: _onCountingDone,
                      ),
                    )
                  : _ScoreBoardFront(
                      theme: theme,
                      name: spec.name,
                      avatarId: spec.avatarId,
                      avatarAsset: spec.avatarAsset,
                      defeatedAces: spec.defeatedAces,
                      wearJourneyAccessories: spec.wearJourneyAccessories,
                      score: spec.score,
                      pendingCoins: spec.pendingCoins,
                      roundCoins: spec.roundCoins,
                      beforeScore: spec.beforeScore,
                      roundScore: spec.roundScore,
                      isDealer: spec.isDealer,
                      isCasino: spec.isCasino,
                      raised: widget.isFront,
                      place: spec.place,
                      placeLabel: spec.placeLabel,
                    ),
            );
          },
        ),
      ),
    );
  }
}

class _ScoreBoardShell extends StatelessWidget {
  const _ScoreBoardShell({
    required this.theme,
    required this.child,
    this.raised = true,
    this.place,
    this.placeLabel,
  });

  final AvatarScoreTheme theme;
  final Widget child;
  final bool raised;
  final int? place;
  final String? placeLabel;

  @override
  Widget build(BuildContext context) {
    final gold = Color.lerp(
      theme.ink,
      AppStyle.theme.turnHighlight,
      0.45,
    )!;
    final first = place == 1;
    final second = place == 2;
    final rest = place != null && place! >= 3;
    final hasBanner = placeLabel != null && placeLabel!.isNotEmpty;
    final borderColor = first
        ? gold.withValues(alpha: 0.48)
        : second
        ? gold.withValues(alpha: 0.28)
        : theme.ink.withValues(alpha: raised ? 0.08 : 0.05);
    final borderWidth = first
        ? 1.15
        : second
        ? 0.9
        : 0.6;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: [
          if (first)
            BoxShadow(
              color: gold.withValues(alpha: 0.20),
              blurRadius: 16,
              offset: const Offset(0, 6),
            )
          else if (second)
            BoxShadow(
              color: gold.withValues(alpha: 0.10),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: raised ? .24 : .12),
            blurRadius: raised ? 16 : 8,
            offset: Offset(0, raised ? 8 : 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxHeight < 200;
                final topPad = !hasBanner
                    ? (compact ? 8.0 : 12.0)
                    : first
                    ? (compact ? 26.0 : 32.0)
                    : (compact ? 22.0 : 26.0);
                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    compact ? 8 : 10,
                    topPad,
                    compact ? 8 : 10,
                    compact ? 8 : 10,
                  ),
                  child: child,
                );
              },
            ),
            if (hasBanner)
              _PlaceOverlay(
                accent: gold,
                ink: theme.ink,
                label: placeLabel!,
                first: first,
                second: second,
                rest: rest,
              ),
          ],
        ),
      ),
    );
  }
}

class _PlaceOverlay extends StatelessWidget {
  const _PlaceOverlay({
    required this.accent,
    required this.ink,
    required this.label,
    required this.first,
    required this.second,
    required this.rest,
  });

  final Color accent;
  final Color ink;
  final String label;
  final bool first;
  final bool second;
  final bool rest;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          if (first || second)
            Positioned.fill(
              child: CustomPaint(
                painter: _WinnerOrnamentPainter(
                  color: accent.withValues(alpha: first ? 0.42 : 0.22),
                ),
              ),
            ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _PlaceBanner(
              accent: accent,
              ink: ink,
              label: label,
              first: first,
              second: second,
              rest: rest,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceBanner extends StatelessWidget {
  const _PlaceBanner({
    required this.accent,
    required this.ink,
    required this.label,
    required this.first,
    required this.second,
    required this.rest,
  });

  final Color accent;
  final Color ink;
  final String label;
  final bool first;
  final bool second;
  final bool rest;

  @override
  Widget build(BuildContext context) {
    final fill = first
        ? accent.withValues(alpha: 0.14)
        : second
        ? accent.withValues(alpha: 0.08)
        : AppStyle.theme.muted.withValues(alpha: 0.10);
    final color = rest
        ? AppStyle.theme.muted.withValues(alpha: 0.85)
        : ink.withValues(alpha: first ? 0.82 : 0.72);
    return Container(
      height: first ? 24 : 20,
      alignment: Alignment.center,
      color: fill,
      child: Text(
        label.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppStyle.theme.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: first ? 10 : 9,
          letterSpacing: first ? 1.2 : 0.7,
          height: 1,
        ),
      ),
    );
  }
}

class _WinnerOrnamentPainter extends CustomPainter {
  const _WinnerOrnamentPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    const inset = 9.0;
    const arm = 12.0;
    const radius = 4.5;
    _corner(canvas, stroke, Offset(inset, inset + 22), 1, 1, arm, radius);
    _corner(
      canvas,
      stroke,
      Offset(size.width - inset, inset + 22),
      -1,
      1,
      arm,
      radius,
    );
    _corner(
      canvas,
      stroke,
      Offset(inset, size.height - inset),
      1,
      -1,
      arm,
      radius,
    );
    _corner(
      canvas,
      stroke,
      Offset(size.width - inset, size.height - inset),
      -1,
      -1,
      arm,
      radius,
    );
  }

  void _corner(
    Canvas canvas,
    Paint paint,
    Offset origin,
    double dx,
    double dy,
    double arm,
    double radius,
  ) {
    final path = Path()
      ..moveTo(origin.dx + dx * arm, origin.dy)
      ..lineTo(origin.dx + dx * radius, origin.dy)
      ..quadraticBezierTo(
        origin.dx,
        origin.dy,
        origin.dx,
        origin.dy + dy * radius,
      )
      ..lineTo(origin.dx, origin.dy + dy * arm);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WinnerOrnamentPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _ScoreBoardFront extends StatelessWidget {
  const _ScoreBoardFront({
    required this.theme,
    required this.name,
    required this.avatarId,
    required this.avatarAsset,
    required this.defeatedAces,
    required this.wearJourneyAccessories,
    required this.score,
    required this.pendingCoins,
    required this.roundCoins,
    required this.beforeScore,
    required this.roundScore,
    required this.isDealer,
    required this.isCasino,
    this.raised = true,
    this.place,
    this.placeLabel,
  });

  final AvatarScoreTheme theme;
  final String name;
  final String? avatarId;
  final String? avatarAsset;
  final Set<JourneyWorld> defeatedAces;
  final bool wearJourneyAccessories;
  final dynamic score;
  final int pendingCoins;
  final int roundCoins;
  final int beforeScore;
  final int roundScore;
  final bool isDealer;
  final bool isCasino;
  final bool raised;
  final int? place;
  final String? placeLabel;

  @override
  Widget build(BuildContext context) {
    final ink = theme.ink;
    return _ScoreBoardShell(
      theme: theme,
      raised: raised,
      place: place,
      placeLabel: placeLabel,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scale = (constraints.maxHeight / 210).clamp(0.62, 1.0);
          final tiny = constraints.maxHeight < 150;
          final avatarSize = (56 * scale).clamp(32.0, 56.0);
          final nameSize = (13 * scale).clamp(10.0, 13.0);
          final scoreSize = (40 * scale).clamp(24.0, 40.0);
          final coinSize = (14 * scale).clamp(11.0, 14.0);
          final coinIconSize = (16 * scale).clamp(12.0, 16.0);
          final eqSize = (16 * scale).clamp(11.0, 16.0);
          final eqNowSize = (18 * scale).clamp(12.0, 18.0);
          final gap = (10 * scale).clamp(4.0, 10.0);
          final panelPad = (8 * scale).clamp(4.0, 8.0);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: PlayerScoreAvatar(
                  avatarId: avatarId,
                  avatarAsset: avatarAsset,
                  defeatedAces: defeatedAces,
                  wearJourneyAccessories: wearJourneyAccessories,
                  score: score,
                  pendingCoins: 0,
                  size: avatarSize,
                ),
              ),
              SizedBox(height: gap),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppStyle.theme.body.copyWith(
                        fontWeight: FontWeight.w700,
                        color: ink,
                        fontSize: nameSize,
                        height: 1.1,
                      ),
                    ),
                  ),
                  if (isDealer) ...[
                    const SizedBox(width: 4),
                    Text(
                      'Dealer',
                      style: AppStyle.theme.caption.copyWith(
                        color: theme.muted,
                        fontSize: (10 * scale).clamp(8.0, 10.0),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
              const Spacer(),
              Text(
                '$score',
                textAlign: TextAlign.center,
                style: AppStyle.theme.title.copyWith(
                  fontSize: scoreSize,
                  fontWeight: FontWeight.w800,
                  color: ink,
                  height: 1,
                ),
              ),
              if (roundCoins > 0) ...[
                SizedBox(height: (4 * scale).clamp(2.0, 4.0)),
                Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: (10 * scale).clamp(7.0, 10.0),
                      vertical: (4 * scale).clamp(2.0, 4.0),
                    ),
                    decoration: BoxDecoration(
                      color: theme.panel.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppStyle.theme.turnHighlight.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.money_dollar_circle_fill,
                          size: coinIconSize,
                          color: AppStyle.theme.turnHighlight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '+$roundCoins',
                          style: AppStyle.theme.body.copyWith(
                            color: ink,
                            fontWeight: FontWeight.w800,
                            fontSize: coinSize,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (isCasino)
                Container(
                  padding: EdgeInsets.all(panelPad),
                  decoration: BoxDecoration(
                    color: theme.panel.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(tiny ? 8 : 12),
                  ),
                  child: Column(
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '$beforeScore',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: ink,
                                  fontSize: eqSize,
                                ),
                              ),
                              TextSpan(
                                text: '  +  ',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: theme.muted,
                                  fontSize: eqSize - 2,
                                ),
                              ),
                              TextSpan(
                                text: '$roundScore',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: ink,
                                  fontSize: eqSize,
                                ),
                              ),
                              TextSpan(
                                text: '  =  ',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: theme.muted,
                                  fontSize: eqSize - 2,
                                ),
                              ),
                              TextSpan(
                                text: '$score',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: ink,
                                  fontSize: eqNowSize,
                                ),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                        ),
                      ),
                      if (!tiny) ...[
                        const SizedBox(height: 2),
                        Text(
                          'last  +  round  =  now',
                          textAlign: TextAlign.center,
                          style: AppStyle.theme.caption.copyWith(
                            color: theme.muted,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ScoreBoardBack extends StatefulWidget {
  const _ScoreBoardBack({
    super.key,
    required this.theme,
    required this.avatarId,
    required this.avatarAsset,
    required this.defeatedAces,
    required this.wearJourneyAccessories,
    required this.isCasino,
    required this.scoreMap,
    required this.matchCoins,
    required this.showMatchCoins,
    this.raised = true,
    this.place,
    this.placeLabel,
    this.playReveal = false,
    this.onRevealDone,
  });

  final AvatarScoreTheme theme;
  final String? avatarId;
  final String? avatarAsset;
  final Set<JourneyWorld> defeatedAces;
  final bool wearJourneyAccessories;
  final bool isCasino;
  final Map<String, dynamic> scoreMap;
  final int matchCoins;
  final bool showMatchCoins;
  final bool raised;
  final int? place;
  final String? placeLabel;
  final bool playReveal;
  final VoidCallback? onRevealDone;

  @override
  State<_ScoreBoardBack> createState() => _ScoreBoardBackState();
}

class _ScoreBoardBackState extends State<_ScoreBoardBack> {
  int _shownPoints = 0;
  int _shownCoins = 0;
  int _points = 0;
  int _coins = 0;
  bool _started = false;

  int _n(String key) => (widget.scoreMap[key] as num?)?.toInt() ?? 0;

  List<({String label, int amount})> get _pointChips => [
    if (_n('A') != 0) (label: 'Aces', amount: _n('A')),
    if (_n('2♠') != 0) (label: '2♠', amount: _n('2♠')),
    if (_n('10♦') != 0) (label: '10♦', amount: _n('10♦')),
    if (_n('pi') != 0) (label: 'Pi', amount: _n('pi')),
    if (_n('carta') != 0) (label: 'Most cards', amount: _n('carta')),
    if (_n('virao') != 0) (label: 'Viraos', amount: _n('virao')),
  ];

  List<({String label, int amount})> get _coinChips => [
    if (widget.showMatchCoins) ...const [],
    if (!widget.showMatchCoins && _n('coinsTake') > 0)
      (label: 'Big take', amount: _n('coinsTake')),
    if (!widget.showMatchCoins && _n('coinsSpecial') > 0)
      (label: 'Special cards', amount: _n('coinsSpecial')),
    if (!widget.showMatchCoins && _n('coinsVirao') > 0)
      (label: 'Viraos', amount: _n('coinsVirao')),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.playReveal) {
      if (widget.showMatchCoins) {
        // Match payout coins are already known; hide the per-round chip
        // animation so the tally shows the total immediately.
        _coins = widget.matchCoins;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _runReveal();
      });
    } else {
      _shownPoints = _pointChips.length;
      _shownCoins = widget.showMatchCoins ? 0 : _coinChips.length;
      _points = _n('total');
      _coins = widget.showMatchCoins ? widget.matchCoins : _n('coins');
    }
  }

  Future<void> _runReveal() async {
    if (_started) return;
    _started = true;
    await Future<void>.delayed(const Duration(milliseconds: 280));
    for (final chip in _pointChips) {
      if (!mounted) return;
      setState(() {
        _shownPoints++;
        _points += chip.amount;
      });
      AppHaptics.selectionClick();
      SoundService.instance.playLayered(GameSound.softCard, volume: 0.35);
      await Future<void>.delayed(const Duration(milliseconds: 420));
    }
    for (final chip in _coinChips) {
      if (!mounted) return;
      setState(() {
        _shownCoins++;
        _coins += chip.amount;
      });
      AppHaptics.lightImpact();
      SoundService.instance.playLayered(GameSound.coin, volume: 0.7);
      await Future<void>.delayed(const Duration(milliseconds: 420));
    }
    if (!mounted) return;
    widget.onRevealDone?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final ink = theme.ink;
    final pointChips = _pointChips;
    final coinChips = _coinChips;
    final shownPoints = pointChips.take(_shownPoints).toList();
    final shownCoins = coinChips.take(_shownCoins).toList();

    return _ScoreBoardShell(
      theme: theme,
      raised: widget.raised,
      place: widget.place,
      placeLabel: widget.placeLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.isCasino) ...[
            Row(
              children: [
                PlayerAvatarView(
                  avatarId: widget.avatarId,
                  avatarAsset: widget.avatarAsset,
                  size: 26,
                  showBorder: false,
                  showJourneyAces: widget.defeatedAces.isNotEmpty,
                  defeatedAces: widget.defeatedAces,
                  wearJourneyAccessories: widget.wearJourneyAccessories,
                ),
                const SizedBox(width: 8),
                _TallyText(
                  value: _points,
                  prefix: '+',
                  style: AppStyle.theme.title.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: ink,
                    height: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Last round',
              style: AppStyle.theme.caption.copyWith(
                color: theme.muted,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: pointChips.isEmpty
                  ? Center(
                      child: Text(
                        'No points this round',
                        textAlign: TextAlign.center,
                        style: AppStyle.theme.caption.copyWith(
                          color: theme.muted,
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          for (final chip in shownPoints)
                            _PopIn(
                              key: ValueKey('p-${chip.label}'),
                              child: _MiniDetailChip(
                                label: chip.label,
                                value: '+${chip.amount}',
                                scoreTheme: theme,
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
          ] else
            const Spacer(),
          Container(height: 1, color: theme.ink.withValues(alpha: 0.18)),
          const SizedBox(height: 8),
          if (coinChips.isNotEmpty)
            Wrap(
              spacing: 4,
              runSpacing: 4,
              alignment: WrapAlignment.end,
              children: [
                for (final chip in shownCoins)
                  _PopIn(
                    key: ValueKey('c-${chip.label}'),
                    child: _MiniDetailChip(
                      label: chip.label,
                      value: '+${chip.amount}',
                      coin: true,
                      scoreTheme: theme,
                    ),
                  ),
              ],
            )
          else
            const SizedBox(height: 4),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(coinIcon, size: 14, color: theme.foreground),
                const SizedBox(width: 4),
                _TallyText(
                  value: _coins,
                  prefix: '+',
                  style: AppStyle.theme.title.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: ink,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TallyText extends StatefulWidget {
  const _TallyText({
    required this.value,
    required this.style,
    this.prefix = '',
  });

  final int value;
  final TextStyle style;
  final String prefix;

  @override
  State<_TallyText> createState() => _TallyTextState();
}

class _TallyTextState extends State<_TallyText> {
  late IntTween _tween;

  @override
  void initState() {
    super.initState();
    _tween = IntTween(begin: widget.value, end: widget.value);
  }

  @override
  void didUpdateWidget(covariant _TallyText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _tween = IntTween(begin: oldWidget.value, end: widget.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: _tween,
      duration: const Duration(milliseconds: 280),
      builder: (context, n, _) =>
          Text('${widget.prefix}$n', style: widget.style),
    );
  }
}

class _PopIn extends StatefulWidget {
  const _PopIn({super.key, required this.child});

  final Widget child;

  @override
  State<_PopIn> createState() => _PopInState();
}

class _PopInState extends State<_PopIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _t;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    )..forward();
    _t = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _t,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.82, end: 1).animate(_t),
        child: widget.child,
      ),
    );
  }
}

class _MiniDetailChip extends StatelessWidget {
  const _MiniDetailChip({
    required this.label,
    required this.value,
    this.coin = false,
    this.scoreTheme,
  });

  final String label;
  final String value;
  final bool coin;
  final AvatarScoreTheme? scoreTheme;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final themed = scoreTheme;
    final Color labelColor;
    final Color valueColor;
    final Color fill;
    final Color border;

    if (themed != null) {
      fill = coin
          ? themed.foreground.withValues(alpha: 0.16)
          : themed.ink.withValues(alpha: 0.12);
      border = coin
          ? themed.foreground.withValues(alpha: 0.4)
          : themed.ink.withValues(alpha: 0.22);
      labelColor = coin
          ? themed.foreground
          : themed.ink.withValues(alpha: 0.88);
      valueColor = coin ? themed.foreground : themed.ink;
    } else {
      labelColor = coin
          ? theme.turnHighlight.withValues(alpha: .9)
          : theme.cardBackground.withValues(alpha: .88);
      valueColor = coin ? theme.turnHighlight : theme.cardBackground;
      fill = coin
          ? theme.turnHighlight.withValues(alpha: .14)
          : theme.suitBlack.withValues(alpha: .82);
      border = coin
          ? theme.turnHighlight.withValues(alpha: .4)
          : theme.suitBlack.withValues(alpha: .9);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.caption.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: labelColor,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: theme.caption.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusIconButton extends StatelessWidget {
  const _StatusIconButton({
    required this.icon,
    required this.onPressed,
    this.danger = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final gold = AppStyle.theme.turnHighlight;
    final accent = danger ? AppStyle.theme.danger : gold;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: SoundService.wrapTap(() {
        AppHaptics.lightImpact();
        onPressed();
      }),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: accent, width: 1.4),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: accent),
      ),
    );
  }
}

class _StatusHomeButton extends StatelessWidget {
  const _StatusHomeButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final gold = AppStyle.theme.turnHighlight;
    final dark = AppStyle.theme.background;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: SoundService.wrapTap(() {
        AppHaptics.lightImpact();
        onPressed();
      }),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: gold,
          shape: BoxShape.circle,
          border: Border.all(color: gold, width: 1.4),
        ),
        alignment: Alignment.center,
        child: Icon(CupertinoIcons.house_fill, size: 28, color: dark),
      ),
    );
  }
}
