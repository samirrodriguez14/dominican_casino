import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/widgets/coin_icon.dart';
import 'package:dominican_casino/view_models/games/general_game_view_model.dart';
import 'package:flutter/cupertino.dart';

/// Match bonus + pot tally. Wallet credit happens on home.
class MatchCoinPayout extends StatelessWidget {
  const MatchCoinPayout({super.key, required this.vm});

  final GeneralGameViewModel vm;

  int get _bonuses => vm.gameState.pendingCoinsFor(vm.me);
  int get _pot => vm.gameState.winPotCoins(vm.me);
  int get _total => _bonuses + _pot;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final l10n = AppLocalizations.of(context);
    if (_total <= 0) {
      return const SizedBox.shrink();
    }

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
            l10n.coinsThisGame,
            textAlign: TextAlign.center,
            style: theme.caption.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 10),
          if (_bonuses > 0) _line(l10n.coinBonuses, _bonuses, theme),
          if (_pot > 0) ...[
            if (_bonuses > 0) const SizedBox(height: 6),
            _line(l10n.coinWinPot, _pot, theme),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                coinIcon,
                size: 22,
                color: theme.turnHighlight,
              ),
              const SizedBox(width: 8),
              Text(
                '$_total',
                style: theme.title.copyWith(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: theme.turnHighlight,
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _line(String label, int value, AppTheme theme) {
    return Row(
      children: [
        Expanded(child: Text(label, style: theme.body)),
        Icon(
          coinIcon,
          size: 14,
          color: theme.turnHighlight,
        ),
        const SizedBox(width: 4),
        Text(
          '$value',
          style: theme.title.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
