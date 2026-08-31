import 'dart:async';

import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/models/game_state.dart';
import 'package:dominican_casino/models/quick_match_prefs.dart';
import 'package:dominican_casino/models/wallet_config.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/routing/game_routes.dart';
import 'package:dominican_casino/services/quick_match_service.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/app_shell/games/game_mode_actions.dart';
import 'package:dominican_casino/ui/app_shell/games/game_mode_carousel.dart';
import 'package:dominican_casino/ui/widgets/coin_icon.dart';
import 'package:dominican_casino/ui/widgets/wallet_dialogs.dart';
import 'package:dominican_casino/view_models/games_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Material;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

String _modeLabel(GamesViewModel vm, GameMode mode) {
  for (final game in vm.gamesInfo) {
    if (game.id == mode.name) return game.title;
  }
  return switch (mode) {
    GameMode.casino => 'Casino',
    GameMode.casinoSpeed => 'Casino Speed',
    GameMode.tresydos => 'Tres y Dos',
    GameMode.rummy => 'Rummy',
    GameMode.robaito => 'Robaito',
    GameMode.bs => 'BS',
  };
}

String _prefsSummary(
  BuildContext context,
  QuickMatchPrefs prefs,
  GamesViewModel vm,
) {
  final l10n = AppLocalizations.of(context);
  final String games;
  if (prefs.anyMode) {
    games = l10n.quickMatchAnyGameDetail;
  } else if (prefs.selectedModes.length == 1) {
    games = _modeLabel(vm, prefs.selectedModes.first);
  } else {
    final first = _modeLabel(vm, prefs.selectedModes.first);
    final more = prefs.selectedModes.length - 1;
    games = '$first ${l10n.quickMatchMoreGames(more)}';
  }
  return [
    games,
    l10n.quickMatchMaxCoins(prefs.maxEntryCost),
    l10n.quickMatchMaxPlayersDetail(prefs.maxPlayers),
  ].join('\n');
}

Future<void> showQuickPlayDialog(BuildContext context) async {
  final repo = context.read<AppRepo>();
  final vm = context.read<GamesViewModel>();
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: CupertinoColors.black.withValues(alpha: .55),
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return _QuickPlayPopup(
        initial: repo.quickMatchPrefs,
        modeTitle: (mode) => _modeLabel(vm, mode),
        summary: (prefs) => _prefsSummary(context, prefs, vm),
        onSavePrefs: repo.setQuickMatchPrefs,
        onSearch: (prefs) async {
          Navigator.pop(dialogContext);
          await _runQuickMatchSearch(context, prefs);
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

Future<void> _runQuickMatchSearch(
  BuildContext context,
  QuickMatchPrefs prefs,
) async {
  if (!await ensureGoogleForOnlinePlay(context)) return;
  if (!context.mounted) return;

  final repo = context.read<AppRepo>();
  final pid = repo.player?.id;
  if (pid == null || pid.isEmpty) return;

  // Pre-check affordability for the cheapest energy among selected modes
  // and the max stake filter.
  final modes = QuickMatchService.energyModesFor(prefs);
  final needsEnergy = modes.any((m) => !repo.canAffordEnergy(m));
  if (needsEnergy) {
    await showInsufficientFundsDialog(context, energy: true);
    return;
  }
  if (!repo.canAffordStake(prefs.maxEntryCost)) {
    // Still allow if they can afford a lower stake the matcher might pick;
    // only block when they cannot afford even the lowest common stake (0).
    final lowest = WalletConfig.stakesFor(allowNoBet: true).first;
    if (!repo.canAffordStake(lowest)) {
      await showInsufficientFundsDialog(context, energy: false);
      return;
    }
  }

  final cancel = Completer<void>();
  var dismissed = false;

  showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Searching',
    barrierColor: CupertinoColors.black.withValues(alpha: .55),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return _SearchingPopup(
        timeout: QuickMatchService.searchTimeout,
        onCancel: () {
          if (!cancel.isCompleted) cancel.complete();
          if (!dismissed) {
            dismissed = true;
            Navigator.pop(dialogContext);
          }
        },
      );
    },
  );

  final outcome = await QuickMatchService(repo.fs).findMatch(
    prefs: prefs,
    playerId: pid,
    displayName: repo.player?.name,
    avatarId: repo.player?.avatarId,
    cancel: cancel.future,
  );

  if (!context.mounted) return;
  if (!dismissed) {
    dismissed = true;
    Navigator.of(context, rootNavigator: true).pop();
  }

  if (outcome.kind == QuickMatchOutcomeKind.cancelled) return;

  if (outcome.kind == QuickMatchOutcomeKind.timedOut ||
      outcome.gameId == null ||
      outcome.gameMode == null) {
    final l10n = AppLocalizations.of(context);
    await showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l10n.quickMatchNoMatches),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: SoundService.wrapTap(() => Navigator.pop(ctx)),
            child: Text(l10n.back),
          ),
        ],
      ),
    );
    return;
  }

  final mode = outcome.gameMode!;
  if (!repo.canAffordEnergy(mode)) {
    await showInsufficientFundsDialog(context, energy: true);
    return;
  }

  context.go(
    GameRoutes.game(gameId: outcome.gameId!, gameMode: mode.name),
  );
}

class _SearchingPopup extends StatefulWidget {
  const _SearchingPopup({
    required this.onCancel,
    required this.timeout,
  });

  final VoidCallback onCancel;
  final Duration timeout;

  /// Show remaining time after this much search has elapsed.
  static const _showCountdownAfter = Duration(seconds: 3);

  @override
  State<_SearchingPopup> createState() => _SearchingPopupState();
}

class _SearchingPopupState extends State<_SearchingPopup> {
  late int _secondsLeft;
  late final DateTime _startedAt;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _secondsLeft = widget.timeout.inSeconds;
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final elapsed = DateTime.now().difference(_startedAt);
      final left = widget.timeout - elapsed;
      setState(() {
        _secondsLeft = left.inSeconds.clamp(0, widget.timeout.inSeconds);
      });
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  bool get _showCountdown {
    final elapsed = DateTime.now().difference(_startedAt);
    return elapsed >= _SearchingPopup._showCountdownAfter;
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Material(
        color: CupertinoColors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 36),
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 12),
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.border.withValues(alpha: .7)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CupertinoActivityIndicator(radius: 14),
              const SizedBox(height: 16),
              Text(
                l10n.quickMatchSearching,
                textAlign: TextAlign.center,
                style: theme.title.copyWith(fontSize: 16),
              ),
              if (_showCountdown) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.quickMatchSecondsLeft(_secondsLeft),
                  textAlign: TextAlign.center,
                  style: theme.body.copyWith(
                    fontSize: 13,
                    color: theme.muted,
                  ),
                ),
              ],
              CupertinoButton(
                onPressed: SoundService.wrapTap(widget.onCancel),
                child: Text(l10n.cancel, style: TextStyle(color: theme.muted)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickPlayPopup extends StatefulWidget {
  const _QuickPlayPopup({
    required this.initial,
    required this.modeTitle,
    required this.summary,
    required this.onSavePrefs,
    required this.onSearch,
  });

  final QuickMatchPrefs initial;
  final String Function(GameMode mode) modeTitle;
  final String Function(QuickMatchPrefs prefs) summary;
  final Future<void> Function(QuickMatchPrefs prefs) onSavePrefs;
  final Future<void> Function(QuickMatchPrefs prefs) onSearch;

  @override
  State<_QuickPlayPopup> createState() => _QuickPlayPopupState();
}

class _QuickPlayPopupState extends State<_QuickPlayPopup> {
  late QuickMatchPrefs _prefs;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _prefs = widget.initial;
  }

  Future<void> _persist(QuickMatchPrefs next) async {
    setState(() => _prefs = next);
    await widget.onSavePrefs(next);
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
            margin: const EdgeInsets.symmetric(horizontal: 24),
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
                  l10n.quickPlay,
                  style: theme.title.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                if (!_editing) ...[
                  Text(
                    widget.summary(_prefs),
                    textAlign: TextAlign.center,
                    style: theme.body.copyWith(color: theme.muted, fontSize: 14),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.only(top: 4),
                    onPressed: SoundService.wrapTap(
                      () => setState(() => _editing = true),
                    ),
                    child: Text(l10n.edit),
                  ),
                ] else
                  _PrefsEditor(
                    prefs: _prefs,
                    modeTitle: widget.modeTitle,
                    onChanged: _persist,
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    color: theme.turnHighlight,
                    borderRadius: BorderRadius.circular(14),
                    onPressed: SoundService.wrapTap(
                      () => widget.onSearch(_prefs),
                    ),
                    child: Text(
                      l10n.quickMatchStart,
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

class _PrefsEditor extends StatelessWidget {
  const _PrefsEditor({
    required this.prefs,
    required this.modeTitle,
    required this.onChanged,
  });

  final QuickMatchPrefs prefs;
  final String Function(GameMode mode) modeTitle;
  final Future<void> Function(QuickMatchPrefs prefs) onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final l10n = AppLocalizations.of(context);
    final stakes = WalletConfig.stakesFor(allowNoBet: true);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.quickMatchGames, style: theme.title.copyWith(fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _FilterChip(
              label: l10n.quickMatchAnyGame,
              selected: prefs.anyMode,
              onTap: () => onChanged(prefs.copyWith(modes: const [])),
            ),
            for (final mode in gameModeCarouselModes)
              _FilterChip(
                label: modeTitle(mode),
                selected: !prefs.anyMode && prefs.modes.contains(mode),
                onTap: () {
                  final next = prefs.anyMode
                      ? <GameMode>[mode]
                      : List<GameMode>.from(prefs.modes);
                  if (!prefs.anyMode) {
                    if (next.contains(mode)) {
                      next.remove(mode);
                    } else {
                      next.add(mode);
                    }
                  }
                  final normalized =
                      next.isEmpty ||
                          next.length >= gameModeCarouselModes.length
                      ? const <GameMode>[]
                      : next;
                  onChanged(prefs.copyWith(modes: normalized));
                },
              ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          l10n.quickMatchMaxStake,
          style: theme.title.copyWith(fontSize: 13),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final stake in stakes) ...[
              if (stake != stakes.first) const SizedBox(width: 6),
              Expanded(
                child: _FilterChip(
                  label: '$stake',
                  selected: prefs.maxEntryCost == stake,
                  icon: coinIcon,
                  onTap: () => onChanged(prefs.copyWith(maxEntryCost: stake)),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),
        Text(
          l10n.quickMatchPlayers,
          style: theme.title.copyWith(fontSize: 13),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final n in const [2, 3, 4, 5, 6])
              _FilterChip(
                label: '$n',
                selected: prefs.maxPlayers == n,
                onTap: () => onChanged(prefs.copyWith(maxPlayers: n)),
              ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: SoundService.wrapTap(onTap),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? theme.surfaceRaised : theme.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? theme.turnHighlight.withValues(alpha: .7)
                : theme.border.withValues(alpha: .55),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 12,
                color: selected ? theme.turnHighlight : theme.muted,
              ),
              const SizedBox(width: 3),
            ],
            Text(
              label,
              style: theme.title.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? theme.textPrimary : theme.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
