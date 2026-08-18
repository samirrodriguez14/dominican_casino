import 'package:dominican_casino/game_control/casino_coin_bonuses.dart';
import 'package:dominican_casino/game_control/game_registry.dart';
import 'package:dominican_casino/models/playing_card_model.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/widgets/card_coin_hint.dart';
import 'package:dominican_casino/view_models/games/general_game_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PlayingCard extends StatelessWidget {
  final PlayingCardModel playingCardModel;
  final double width;
  final double heightMultiplyer;
  final VoidCallback? onTap;
  final bool isSelected;

  final Color? selectedBorderColor;
  final double selectedBorderWidth;

  /// Extra coin hint (e.g. take-size preview). Specials are automatic.
  final int extraCoinHint;

  /// Flight overlays skip hints so they do not mount extra bounce listeners.
  final bool showCoinHint;

  const PlayingCard({
    super.key,
    required this.playingCardModel,
    this.width = 80,
    this.heightMultiplyer = 1.4,
    this.onTap,
    required this.isSelected,
    this.selectedBorderColor,
    this.selectedBorderWidth = 2.4,
    this.extraCoinHint = 0,
    this.showCoinHint = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final rank = playingCardModel.rank;
    final suit = _normalizeSuit(playingCardModel.suit);
    final suitColor = _suitColor(suit, theme);
    final height = width * heightMultiplyer;
    final hintsEnabled = showCoinHint && _casinoCoinHintsEnabled(context);
    final specialCoins = hintsEnabled
        ? CasinoCoinBonuses.specialBonus(playingCardModel)
        : 0;
    final coinHint = hintsEnabled
        ? (extraCoinHint > 0 ? extraCoinHint : specialCoins)
        : 0;

    final sel = selectedBorderColor ?? theme.turnHighlight;
    final metrics = _CardMetrics(width, rank);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: theme.cardBackground,
          borderRadius: BorderRadius.circular(metrics.radius),
          border: Border.all(
            color: isSelected ? sel : theme.cardBorder,
            width: 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: width * 0.28,
                spreadRadius: 1,
                offset: Offset(0, width * 0.12),
              ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: metrics.shadowBlur,
              offset: Offset(0, metrics.shadowY),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: metrics.pad,
              left: metrics.pad,
              child: _CornerIndex(
                rank: rank,
                suit: suit,
                color: suitColor,
                metrics: metrics,
              ),
            ),
            Center(
              child: Text(
                suit,
                style: TextStyle(
                  fontSize: metrics.centerSize,
                  height: 1,
                  color: suitColor,
                ),
              ),
            ),
            Positioned(
              bottom: metrics.pad,
              right: metrics.pad,
              child: Transform.rotate(
                angle: 3.1416,
                child: _CornerIndex(
                  rank: rank,
                  suit: suit,
                  color: suitColor,
                  metrics: metrics,
                ),
              ),
            ),
            if (coinHint > 0)
              Positioned(
                bottom: metrics.pad * 0.5,
                left: metrics.pad * 0.5,
                child: CardCoinHint(
                  count: coinHint,
                  size: (width * 0.16).clamp(9, 14),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CardMetrics {
  _CardMetrics(this.width, String rank)
    : radius = (width * 0.125).clamp(6.0, 14.0),
      pad = (width * 0.075).clamp(4.0, 8.0),
      rankSize = _rankSize(width, rank),
      cornerSuitSize = (width * 0.22).clamp(12.0, 16.0),
      centerSize = width * 0.46,
      shadowBlur = (width * 0.12).clamp(4.0, 10.0),
      shadowY = (width * 0.045).clamp(2.0, 4.0);

  final double width;
  final double radius;
  final double pad;
  final double rankSize;
  final double cornerSuitSize;
  final double centerSize;
  final double shadowBlur;
  final double shadowY;

  static double _rankSize(double width, String rank) {
    final base = (width * 0.28).clamp(15.0, 20.0);
    return rank.length > 1 ? base * 0.86 : base;
  }
}

class _CornerIndex extends StatelessWidget {
  const _CornerIndex({
    required this.rank,
    required this.suit,
    required this.color,
    required this.metrics,
  });

  final String rank;
  final String suit;
  final Color color;
  final _CardMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rank,
          style: TextStyle(
            fontSize: metrics.rankSize,
            fontWeight: FontWeight.w700,
            height: 1,
            letterSpacing: rank.length > 1 ? -0.5 : 0,
            color: color,
          ),
        ),
        Text(
          suit,
          style: TextStyle(
            fontSize: metrics.cornerSuitSize,
            height: 1.05,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Coin markers are Casino / Casino Speed only (not Tres y Dos).
bool _casinoCoinHintsEnabled(BuildContext context) {
  try {
    final vm = Provider.of<GeneralGameViewModel>(context, listen: false);
    return GameRegistry.isCasinoFamily(vm.gameState.gameMode);
  } on ProviderNotFoundException {
    return false;
  }
}

/// Allows either "hearts" or "♥"
String _normalizeSuit(String suit) {
  switch (suit.toLowerCase()) {
    case 'hearts':
    case '♥':
      return '♥';
    case 'diamonds':
    case '♦':
      return '♦';
    case 'spades':
    case '♠':
      return '♠';
    case 'clubs':
    case '♣':
      return '♣';
    default:
      return suit;
  }
}

Color _suitColor(String suit, AppTheme theme) {
  return (suit == '♥' || suit == '♦') ? theme.suitRed : theme.suitBlack;
}
