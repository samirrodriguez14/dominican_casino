import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/instructions.dart';
import 'package:dominican_casino/models/wallet_config.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/routing/game_routes.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/ui/widgets/coin_icon.dart';
import 'package:dominican_casino/ui/widgets/wallet_dialogs.dart';
import 'package:dominican_casino/view_models/games_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Material;
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

void showJoinGameDialog(BuildContext context, String mode) {
  final TextEditingController controller = TextEditingController();
  final l10n = AppLocalizations.of(context);

  showCupertinoDialog(
    context: context,
    builder: (context) {
      return CupertinoAlertDialog(
        title: Text(l10n.joinGame),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            children: [
              Text(
                l10n.joinCostsEnergy(
                  WalletConfig.energyCostFor(mode),
                ),
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 10),
              CupertinoTextField(
                controller: controller,
                placeholder: l10n.enterGameId,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: Text(l10n.cancel),
            onPressed: SoundService.wrapTap(() => Navigator.pop(context)),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text(l10n.join, style: AppStyle.theme.title),
            onPressed: SoundService.wrapTap(() {
              final gameId = controller.text.trim();
              Navigator.pop(context);
              if (gameId.isNotEmpty) {
                context.go(GameRoutes.game(gameId: gameId, gameMode: mode));
              }
            }),
          ),
        ],
      );
    },
  );
}

void showEnterGameDialog(
  BuildContext context,
  GamesViewModel vm,
  GameMode mode,
) {
  showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: CupertinoColors.black.withValues(alpha: .55),
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return _EnterGamePopup(
        mode: mode,
        onFriend: (entryCost) async {
          if (!await ensureGoogleForOnlinePlay(context)) return;
          if (!context.mounted) return;
          Navigator.pop(dialogContext);
          gameEnter(context, vm, mode, false, entryCost: entryCost);
        },
        onPuli: (entryCost) {
          Navigator.pop(dialogContext);
          if (mode == GameMode.tresydos) {
            showAiTableSizeDialog(
              context,
              vm,
              mode,
              entryCost: entryCost,
            );
          } else {
            gameEnter(context, vm, mode, true, entryCost: entryCost);
          }
        },
        onJoin: () async {
          if (!await ensureGoogleForOnlinePlay(context)) return;
          if (!context.mounted) return;
          Navigator.pop(dialogContext);
          showJoinGameDialog(context, mode.name);
        },
        gameTitle: _modeTitle(vm, mode),
      );
    },
    transitionBuilder: (context, animation, secondary, child) {
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          child: child,
        ),
      );
    },
  );
}

Future<bool> ensureGoogleForOnlinePlay(BuildContext context) async {
  final repo = context.read<AppRepo>();
  if (repo.isGoogleLinked) return true;
  final l10n = AppLocalizations.of(context);
  final connect = await showCupertinoDialog<bool>(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      title: Text(l10n.googleRequiredForFriendsTitle),
      content: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(l10n.googleRequiredForFriendsBody),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: SoundService.wrapTap(() => Navigator.pop(ctx, false)),
          child: Text(l10n.cancel),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: SoundService.wrapTap(() => Navigator.pop(ctx, true)),
          child: Text(l10n.connectGoogle),
        ),
      ],
    ),
  );
  if (connect != true || !context.mounted) return false;

  final result = await repo.linkGoogleAccount();
  if (!context.mounted) return false;
  if (result.status == GoogleAuthStatus.canceled) return false;
  if (result.status == GoogleAuthStatus.failed) {
    await showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l10n.google),
        content: Text(l10n.googleSignInError(result.errorCode)),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: SoundService.wrapTap(() => Navigator.pop(ctx)),
            child: Text(l10n.back),
          ),
        ],
      ),
    );
    return false;
  }
  return repo.isGoogleLinked;
}

String _modeTitle(GamesViewModel vm, GameMode mode) {
  for (final game in vm.gamesInfo) {
    if (game.id == mode.name) return game.title;
  }
  return switch (mode) {
    GameMode.casino => 'Casino',
    GameMode.casinoSpeed => 'Casino Speed',
    GameMode.tresydos => 'Tres y Dos',
    GameMode.robaito => 'Robaito',
  };
}

class _StakePicker extends StatelessWidget {
  const _StakePicker({
    required this.stakes,
    required this.selected,
    required this.onChanged,
  });

  final List<int> stakes;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    return Row(
      children: [
        for (var i = 0; i < stakes.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: _StakeChip(
              amount: stakes[i],
              selected: selected == stakes[i],
              onTap: () => onChanged(stakes[i]),
              theme: theme,
            ),
          ),
        ],
      ],
    );
  }
}

class _StakeChip extends StatelessWidget {
  const _StakeChip({
    required this.amount,
    required this.selected,
    required this.onTap,
    required this.theme,
  });

  final int amount;
  final bool selected;
  final VoidCallback onTap;
  final AppTheme theme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        pressedOpacity: 0.72,
        onPressed: SoundService.wrapTap(onTap),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: selected ? theme.surfaceRaised : theme.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? theme.turnHighlight.withValues(alpha: .7)
                  : theme.border.withValues(alpha: .55),
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  coinIcon,
                  size: 13,
                  color: selected ? theme.turnHighlight : theme.muted,
                ),
                const SizedBox(width: 3),
                Text(
                  '$amount',
                  style: theme.title.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: selected ? theme.textPrimary : theme.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EnterGamePopup extends StatefulWidget {
  const _EnterGamePopup({
    required this.mode,
    required this.gameTitle,
    required this.onFriend,
    required this.onPuli,
    required this.onJoin,
  });

  final GameMode mode;
  final String gameTitle;
  final void Function(int entryCost) onFriend;
  final void Function(int entryCost) onPuli;
  final VoidCallback onJoin;

  @override
  State<_EnterGamePopup> createState() => _EnterGamePopupState();
}

class _EnterGamePopupState extends State<_EnterGamePopup> {
  int _stake = WalletConfig.entryCost;
  _PlayPath _path = _PlayPath.friend;

  void _start() {
    switch (_path) {
      case _PlayPath.friend:
        widget.onFriend(_stake);
      case _PlayPath.puli:
        widget.onPuli(_stake);
      case _PlayPath.join:
        widget.onJoin();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final l10n = AppLocalizations.of(context);
    final mode = widget.mode;
    final energy = WalletConfig.energyCostFor(mode.name);
    final energyCost = _EntryCost(
      label: '$energy',
      icon: CupertinoIcons.bolt_fill,
      energy: true,
    );
    final suitColor = switch (mode) {
      GameMode.tresydos => theme.suitRed,
      GameMode.casino ||
      GameMode.casinoSpeed ||
      GameMode.robaito => theme.textPrimary,
    };
    final suit = switch (mode) {
      GameMode.casino || GameMode.casinoSpeed => '♠',
      GameMode.tresydos => '♦',
      GameMode.robaito => '♣',
    };

    return Center(
      child: Material(
        color: CupertinoColors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 28),
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 8),
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.border.withValues(alpha: .7)),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.black.withValues(alpha: .45),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  suit,
                  style: TextStyle(
                    color: suitColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.gameTitle,
                  textAlign: TextAlign.center,
                  style: theme.title.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.playHowPrompt,
                  textAlign: TextAlign.center,
                  style: theme.mutedText.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 18),
                _ChoiceTile(
                  icon: widget.mode == GameMode.tresydos
                      ? CupertinoIcons.group_solid
                      : CupertinoIcons.person_2_fill,
                  title: widget.mode == GameMode.tresydos
                      ? l10n.playWithFriends
                      : l10n.playWithFriend,
                  subtitle: widget.mode == GameMode.tresydos
                      ? l10n.playWithFriendsHint
                      : l10n.playWithFriendHint,
                  costs: [energyCost],
                  emphasized: _path == _PlayPath.friend,
                  onTap: () => setState(() => _path = _PlayPath.friend),
                ),
                const SizedBox(height: 10),
                _ChoiceTile(
                  icon: CupertinoIcons.bolt_fill,
                  title: l10n.playVsPuli,
                  subtitle: l10n.playVsPuliHint,
                  costs: [energyCost],
                  emphasized: _path == _PlayPath.puli,
                  onTap: () => setState(() => _path = _PlayPath.puli),
                ),
                const SizedBox(height: 10),
                _ChoiceTile(
                  icon: CupertinoIcons.number,
                  title: l10n.joinById,
                  subtitle: l10n.playJoinByIdHint,
                  costs: [energyCost],
                  emphasized: _path == _PlayPath.join,
                  onTap: () => setState(() => _path = _PlayPath.join),
                ),
                if (_path != _PlayPath.join) ...[
                  const SizedBox(height: 16),
                  Text(
                    l10n.matchStake,
                    style: theme.mutedText.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _StakePicker(
                    stakes: WalletConfig.stakesFor(
                      allowNoBet:
                          mode == GameMode.casino ||
                          mode == GameMode.casinoSpeed,
                    ),
                    selected: _stake,
                    onChanged: (value) => setState(() => _stake = value),
                  ),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    color: theme.turnHighlight,
                    borderRadius: BorderRadius.circular(14),
                    onPressed: SoundService.wrapTap(_start),
                    child: Text(
                      _path == _PlayPath.join ? l10n.join : l10n.startGame,
                      style: theme.title.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: theme.background,
                      ),
                    ),
                  ),
                ),
                CupertinoButton(
                  padding: const EdgeInsets.only(top: 4),
                  onPressed: SoundService.wrapTap(() => Navigator.pop(context)),
                  child: Text(
                    l10n.cancel,
                    style: TextStyle(color: theme.muted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _PlayPath { friend, puli, join }

class _AiTableSizePopup extends StatefulWidget {
  const _AiTableSizePopup({required this.mode, required this.onStart});

  final GameMode mode;
  final void Function(int playerCount) onStart;

  @override
  State<_AiTableSizePopup> createState() => _AiTableSizePopupState();
}

class _AiTableSizePopupState extends State<_AiTableSizePopup> {
  int _playerCount = 2;

  static const _options = [2, 3, 4];

  IconData _iconFor(int count) {
    return switch (count) {
      2 => CupertinoIcons.person_2_fill,
      3 => CupertinoIcons.group_solid,
      _ => CupertinoIcons.person_2,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Material(
        color: CupertinoColors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 28),
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 8),
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.border.withValues(alpha: .7)),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.black.withValues(alpha: .45),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.playVsPuli,
                  textAlign: TextAlign.center,
                  style: theme.title.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.playHowManyPlayers,
                  textAlign: TextAlign.center,
                  style: theme.mutedText.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 18),
                for (final count in _options) ...[
                  if (count != _options.first) const SizedBox(height: 10),
                  _ChoiceTile(
                    icon: _iconFor(count),
                    title: l10n.playersAtTable(count),
                    subtitle: '${l10n.youPlusBots(count - 1)}. ${l10n.tablePayoutHint(count)}',
                    emphasized: _playerCount == count,
                    onTap: () => setState(() => _playerCount = count),
                  ),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    color: theme.turnHighlight,
                    borderRadius: BorderRadius.circular(14),
                    onPressed: SoundService.wrapTap(
                      () => widget.onStart(_playerCount),
                    ),
                    child: Text(
                      l10n.actionStart,
                      style: theme.title.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: theme.background,
                      ),
                    ),
                  ),
                ),
                CupertinoButton(
                  padding: const EdgeInsets.only(top: 4),
                  onPressed: SoundService.wrapTap(() => Navigator.pop(context)),
                  child: Text(
                    l10n.cancel,
                    style: TextStyle(color: theme.muted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EntryCost {
  const _EntryCost({
    required this.label,
    required this.icon,
    this.energy = false,
  });

  final String label;
  final IconData icon;
  final bool energy;
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.emphasized = false,
    this.costs = const [],
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool emphasized;
  final List<_EntryCost> costs;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    const radius = 14.0;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      pressedOpacity: 0.72,
      onPressed: SoundService.wrapTap(onTap),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: emphasized ? theme.surfaceRaised : theme.background,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: emphasized
                ? theme.turnHighlight.withValues(alpha: .5)
                : theme.border.withValues(alpha: .55),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 3.5,
                  color: emphasized
                      ? theme.turnHighlight
                      : CupertinoColors.transparent,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: emphasized
                                ? theme.turnHighlight.withValues(alpha: .22)
                                : theme.surfaceAlt.withValues(alpha: .55),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            icon,
                            size: 18,
                            color: emphasized
                                ? theme.turnHighlight
                                : theme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                title,
                                style: theme.title.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                style: theme.mutedText.copyWith(
                                  fontSize: 12,
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (costs.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              for (var i = 0; i < costs.length; i++) ...[
                                if (i > 0) const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      costs[i].icon,
                                      size: 14,
                                      color: costs[i].energy
                                          ? theme.warning
                                          : theme.turnHighlight,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      costs[i].label,
                                      style: theme.title.copyWith(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showAiTableSizeDialog(
  BuildContext context,
  GamesViewModel vm,
  GameMode mode, {
  int entryCost = WalletConfig.entryCost,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: CupertinoColors.black.withValues(alpha: .55),
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return _AiTableSizePopup(
        mode: mode,
        onStart: (playerCount) {
          Navigator.pop(dialogContext);
          gameEnter(
            context,
            vm,
            mode,
            true,
            playerCount: playerCount,
            entryCost: entryCost,
          );
        },
      );
    },
    transitionBuilder: (context, animation, secondary, child) {
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          child: child,
        ),
      );
    },
  );
}

Future<void> gameEnter(
  BuildContext context,
  GamesViewModel vm,
  GameMode mode,
  bool local, {
  int playerCount = 2,
  int entryCost = WalletConfig.entryCost,
}) async {
  if (mode == GameMode.robaito) return;
  final repo = context.read<AppRepo>();
  final router = GoRouter.of(context);
  final l10n = AppLocalizations.of(context);
  if (!repo.canAffordEnergy(mode)) {
    await showInsufficientFundsDialog(context, energy: true);
    return;
  }
  if (!repo.canAffordStake(entryCost)) {
    await showInsufficientFundsDialog(context, energy: false);
    return;
  }
  try {
    final gid = await vm.newGame(
      mode,
      local,
      playerCount: playerCount,
      entryCost: entryCost,
    );
    if (gid != null) {
      router.go(GameRoutes.game(gameId: gid, gameMode: mode.name));
    }
  } on InsufficientFundsException catch (e) {
    if (context.mounted) {
      await showInsufficientFundsDialog(context, energy: e.energy);
    }
  } catch (e, st) {
    developer.log('gameEnter: $e', stackTrace: st);
    if (!context.mounted) return;
    await showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l10n.couldNotStartGame),
        content: Text(l10n.tryAgain),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: SoundService.wrapTap(() => Navigator.pop(ctx)),
            child: Text(l10n.back),
          ),
        ],
      ),
    );
  }
}

Future<InstructionsData> loadInstructions(GameMode mode) async {
  final path = switch (mode) {
    GameMode.tresydos => 'assets/config/tresydos_instructions.json',
    GameMode.robaito => 'assets/config/robaito_instructions.json',
    GameMode.casino => 'assets/config/casino_instructions.json',
    GameMode.casinoSpeed => 'assets/config/casino_speed_instructions.json',
  };
  final raw = await rootBundle.loadString(path);
  return InstructionsData.fromJson(jsonDecode(raw));
}
