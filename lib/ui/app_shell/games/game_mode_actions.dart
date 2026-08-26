import 'dart:convert';
import 'dart:async';
import 'dart:developer' as developer;

import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/instructions.dart';
import 'package:dominican_casino/models/local_bot_roster.dart';
import 'package:dominican_casino/models/wallet_config.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/routing/game_routes.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/ui/widgets/account_dialogs.dart';
import 'package:dominican_casino/ui/widgets/coin_icon.dart';
import 'package:dominican_casino/ui/widgets/wallet_dialogs.dart';
import 'package:dominican_casino/view_models/games_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Material;
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

bool _allowsNoBet(GameMode mode) =>
    mode == GameMode.casino ||
    mode == GameMode.casinoSpeed ||
    mode == GameMode.tresydos ||
    mode == GameMode.rummy;

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
            onPressed: SoundService.wrapTap(() => Navigator.pop(context)),
            child: Text(l10n.cancel),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: SoundService.wrapTap(() {
              final gameId = controller.text.trim();
              Navigator.pop(context);
              if (gameId.isNotEmpty) {
                context.go(GameRoutes.game(gameId: gameId, gameMode: mode));
              }
            }),
            child: Text(l10n.join, style: AppStyle.theme.title),
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
        onFriend:
            (
              entryCost, {
              int playerCount = 2,
              int turnDurationSeconds = WalletConfig.defaultSpeedTurnSeconds,
            }) async {
          if (!await ensureGoogleForOnlinePlay(context)) return;
          if (!context.mounted) return;
          Navigator.pop(dialogContext);
          gameEnter(
            context,
            vm,
            mode,
            false,
            entryCost: entryCost,
            playerCount: playerCount,
            turnDurationSeconds: turnDurationSeconds,
          );
        },
        onPuli:
            (
              entryCost, {
              int playerCount = 2,
              int turnDurationSeconds = WalletConfig.defaultSpeedTurnSeconds,
            }) {
          Navigator.pop(dialogContext);
          gameEnter(
            context,
            vm,
            mode,
            true,
            entryCost: entryCost,
            playerCount: playerCount,
            turnDurationSeconds: turnDurationSeconds,
          );
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

Future<bool> ensureGoogleForOnlinePlay(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return ensureLinkedAccount(
    context,
    title: l10n.googleRequiredForFriendsTitle,
    body: l10n.googleRequiredForFriendsBody,
  );
}

String _modeTitle(GamesViewModel vm, GameMode mode) {
  for (final game in vm.gamesInfo) {
    if (game.id == mode.name) return game.title;
  }
  return switch (mode) {
    GameMode.casino => 'Casino',
    GameMode.casinoSpeed => 'Casino Speed',
    GameMode.tresydos => 'Tres y Dos',
    GameMode.rummy => 'Rummy',
    GameMode.robaito => 'Robaito',
  };
}

class _PathPicker extends StatelessWidget {
  const _PathPicker({
    required this.selected,
    required this.onChanged,
    required this.friendTitle,
    required this.friendIcon,
  });

  final _PlayPath selected;
  final ValueChanged<_PlayPath> onChanged;
  final String friendTitle;
  final IconData friendIcon;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: _PathChip(
            icon: friendIcon,
            label: friendTitle,
            selected: selected == _PlayPath.friend,
            onTap: () => onChanged(_PlayPath.friend),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _PathChip(
            icon: CupertinoIcons.bolt_fill,
            label: l10n.playPuliChip,
            selected: selected == _PlayPath.puli,
            onTap: () => onChanged(_PlayPath.puli),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _PathChip(
            icon: CupertinoIcons.number,
            label: l10n.join,
            selected: selected == _PlayPath.join,
            onTap: () => onChanged(_PlayPath.join),
          ),
        ),
      ],
    );
  }
}

class _PathChip extends StatelessWidget {
  const _PathChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? theme.turnHighlight : theme.muted,
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: theme.title.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected ? theme.textPrimary : theme.muted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerCountPicker extends StatelessWidget {
  const _PlayerCountPicker({
    required this.selected,
    required this.onChanged,
  });

  final int selected;
  final ValueChanged<int> onChanged;

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
    return Row(
      children: [
        for (var i = 0; i < _options.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: _PlayerCountChip(
              count: _options[i],
              icon: _iconFor(_options[i]),
              selected: selected == _options[i],
              onTap: () => onChanged(_options[i]),
              theme: theme,
            ),
          ),
        ],
      ],
    );
  }
}

class _PlayerCountChip extends StatelessWidget {
  const _PlayerCountChip({
    required this.count,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.theme,
  });

  final int count;
  final IconData icon;
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? theme.turnHighlight : theme.muted,
              ),
              const SizedBox(height: 4),
              Text(
                '$count',
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
    );
  }
}

class _TurnDurationPicker extends StatelessWidget {
  const _TurnDurationPicker({
    required this.selected,
    required this.onChanged,
  });

  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    return Row(
      children: [
        for (var i = 0; i < WalletConfig.speedTurnOptions.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: _TurnDurationChip(
              seconds: WalletConfig.speedTurnOptions[i],
              selected: selected == WalletConfig.speedTurnOptions[i],
              onTap: () => onChanged(WalletConfig.speedTurnOptions[i]),
              theme: theme,
            ),
          ),
        ],
      ],
    );
  }
}

class _TurnDurationChip extends StatelessWidget {
  const _TurnDurationChip({
    required this.seconds,
    required this.selected,
    required this.onTap,
    required this.theme,
  });

  final int seconds;
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
                  CupertinoIcons.timer,
                  size: 13,
                  color: selected ? theme.turnHighlight : theme.muted,
                ),
                const SizedBox(width: 3),
                Text(
                  '${seconds}s',
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
  final void Function(
    int entryCost, {
    required int playerCount,
    required int turnDurationSeconds,
  })
  onFriend;
  final void Function(
    int entryCost, {
    required int playerCount,
    required int turnDurationSeconds,
  })
  onPuli;
  final VoidCallback onJoin;

  @override
  State<_EnterGamePopup> createState() => _EnterGamePopupState();
}

class _EnterGamePopupState extends State<_EnterGamePopup> {
  int _stake = WalletConfig.entryCost;
  _PlayPath _path = _PlayPath.puli;
  int _playerCount = 2;
  int _turnSeconds = WalletConfig.defaultSpeedTurnSeconds;

  void _start() {
    final playerCount =
        (widget.mode == GameMode.tresydos || widget.mode == GameMode.rummy) &&
                _path == _PlayPath.puli
        ? _playerCount
        : 2;
    final turnDurationSeconds = widget.mode == GameMode.casinoSpeed
        ? _turnSeconds
        : WalletConfig.defaultSpeedTurnSeconds;
    switch (_path) {
      case _PlayPath.friend:
        widget.onFriend(
          _stake,
          playerCount: playerCount,
          turnDurationSeconds: turnDurationSeconds,
        );
      case _PlayPath.puli:
        widget.onPuli(
          _stake,
          playerCount: playerCount,
          turnDurationSeconds: turnDurationSeconds,
        );
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
    final joining = _path == _PlayPath.join;
    final showPlayerCount =
        (mode == GameMode.tresydos || mode == GameMode.rummy) &&
            _path == _PlayPath.puli;
    final showTurnClock = mode == GameMode.casinoSpeed && !joining;

    return Center(
      child: Material(
        color: CupertinoColors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 28),
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 8),
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
                  widget.gameTitle,
                  textAlign: TextAlign.center,
                  style: theme.title.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                _PathPicker(
                  selected: _path,
                  onChanged: (path) => setState(() => _path = path),
                  friendIcon: mode == GameMode.tresydos || mode == GameMode.rummy
                      ? CupertinoIcons.group_solid
                      : CupertinoIcons.person_2_fill,
                  friendTitle: mode == GameMode.tresydos || mode == GameMode.rummy
                      ? l10n.playFriendsChip
                      : l10n.playFriendChip,
                ),
                if (!joining) ...[
                  const SizedBox(height: 14),
                  _StakePicker(
                    stakes: WalletConfig.stakesFor(
                      allowNoBet: _allowsNoBet(mode),
                    ),
                    selected: _stake,
                    onChanged: (value) => setState(() => _stake = value),
                  ),
                ],
                if (showPlayerCount) ...[
                  const SizedBox(height: 14),
                  _PlayerCountPicker(
                    selected: _playerCount,
                    onChanged: (value) => setState(() => _playerCount = value),
                  ),
                ],
                if (showTurnClock) ...[
                  const SizedBox(height: 14),
                  _TurnDurationPicker(
                    selected: _turnSeconds,
                    onChanged: (value) => setState(() => _turnSeconds = value),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.bolt_fill,
                      size: 14,
                      color: theme.warning,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$energy',
                      style: theme.title.copyWith(fontSize: 14),
                    ),
                    if (!joining) ...[
                      const SizedBox(width: 14),
                      Icon(
                        coinIcon,
                        size: 14,
                        color: theme.turnHighlight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$_stake',
                        style: theme.title.copyWith(fontSize: 14),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    color: theme.turnHighlight,
                    borderRadius: BorderRadius.circular(14),
                    onPressed: SoundService.wrapTap(_start),
                    child: Text(
                      joining ? l10n.join : l10n.startGame,
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

Future<void> gameEnter(
  BuildContext context,
  GamesViewModel vm,
  GameMode mode,
  bool local, {
  int playerCount = 2,
  int entryCost = WalletConfig.entryCost,
  int turnDurationSeconds = WalletConfig.defaultSpeedTurnSeconds,
  Future<void> Function(String gameId)? onCreated,
  LocalBotProfile? botOverride,
  List<LocalBotProfile>? botOverrides,
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
      turnDurationSeconds: turnDurationSeconds,
      botOverride: botOverride,
      botOverrides: botOverrides,
    );
    if (gid != null) {
      if (onCreated != null) unawaited(onCreated(gid));
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
    GameMode.rummy => 'assets/config/rummy_instructions.json',
    GameMode.robaito => 'assets/config/robaito_instructions.json',
    GameMode.casino => 'assets/config/casino_instructions.json',
    GameMode.casinoSpeed => 'assets/config/casino_speed_instructions.json',
  };
  final raw = await rootBundle.loadString(path);
  return InstructionsData.fromJson(jsonDecode(raw));
}
