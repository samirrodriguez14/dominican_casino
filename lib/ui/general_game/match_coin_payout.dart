import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/models/experience.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/widgets/coin_icon.dart';
import 'package:dominican_casino/ui/widgets/exp_icon.dart';
import 'package:dominican_casino/view_models/games/general_game_view_model.dart';
import 'package:flutter/cupertino.dart';

/// Match bonus + pot + XP tally. Wallet / profile credit happens on home.
class MatchCoinPayout extends StatelessWidget {
  const MatchCoinPayout({super.key, required this.vm});

  final GeneralGameViewModel vm;

  int get _bonuses => vm.gameState.pendingCoinsFor(vm.me);
  int get _pot => vm.gameState.winPotCoins(vm.me);
  int get _coinTotal => _bonuses + _pot;
  int? get _place => vm.gameState.finishRank(vm.me);

  bool get _won {
    final winner = vm.gameState.winnerId;
    return winner != null && winner.isNotEmpty && winner == vm.me;
  }

  int get _xp => ExperienceConfig.xpForMatch(won: _won);

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final l10n = AppLocalizations.of(context);
    if (_coinTotal <= 0 && _xp <= 0) {
      return const SizedBox.shrink();
    }
    final potLabel = _place != null && vm.gameState.seatedPlayerCount >= 3
        ? l10n.coinPayoutPlace(_place!)
        : l10n.coinWinPot;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.turnHighlight.withValues(alpha: .45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.awardsThisGame,
            textAlign: TextAlign.center,
            style: theme.caption.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 10),
          if (_bonuses > 0)
            _line(
              l10n.coinBonuses,
              _bonuses,
              theme,
              icon: coinIcon,
              color: theme.turnHighlight,
            ),
          if (_pot > 0) ...[
            if (_bonuses > 0) const SizedBox(height: 6),
            _line(
              potLabel,
              _pot,
              theme,
              icon: coinIcon,
              color: theme.turnHighlight,
            ),
          ],
          if (_xp > 0) ...[
            if (_coinTotal > 0) const SizedBox(height: 6),
            _line(
              l10n.xpEarned,
              _xp,
              theme,
              icon: expIcon,
              color: theme.xp,
            ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_coinTotal > 0) ...[
                _totalPill(
                  icon: coinIcon,
                  value: _coinTotal,
                  color: theme.turnHighlight,
                  theme: theme,
                ),
                if (_xp > 0) const SizedBox(width: 16),
              ],
              if (_xp > 0)
                _totalPill(
                  icon: expIcon,
                  value: _xp,
                  color: theme.xp,
                  theme: theme,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _totalPill({
    required IconData icon,
    required int value,
    required Color color,
    required AppTheme theme,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(width: 8),
        Text(
          '$value',
          style: theme.title.copyWith(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: color,
            height: 1,
          ),
        ),
      ],
    );
  }

  Widget _line(
    String label,
    int value,
    AppTheme theme, {
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Expanded(child: Text(label, style: theme.body)),
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          '$value',
          style: theme.title.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
