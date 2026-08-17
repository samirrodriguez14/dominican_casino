import 'package:dominican_casino/services/haptics.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/widgets/coin_icon.dart';
import 'package:dominican_casino/ui/widgets/currency_delta_label.dart';
import 'package:flutter/cupertino.dart';

/// Coin chip next to a player avatar. Pulses and shows +N when [pending] rises.
class CoinGainBadge extends StatefulWidget {
  const CoinGainBadge({
    super.key,
    required this.pending,
    this.compact = false,
  });

  final int pending;
  final bool compact;

  @override
  State<CoinGainBadge> createState() => _CoinGainBadgeState();
}

class _CoinGainBadgeState extends State<CoinGainBadge>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _pop;
  int _shown = 0;
  int _gain = 0;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _pop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    _shown = widget.pending;
  }

  @override
  void didUpdateWidget(covariant CoinGainBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pending > _shown) {
      _gain = widget.pending - _shown;
      _shown = widget.pending;
      _pulse.forward(from: 0);
      _pop.forward(from: 0);
      AppHaptics.lightImpact();
      SoundService.instance.playLayered(GameSound.coin, volume: 0.9);
    } else if (widget.pending != _shown) {
      _shown = widget.pending;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final size = widget.compact ? 11.0 : 12.0;
    if (_shown <= 0 && _gain <= 0) return const SizedBox.shrink();

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        ScaleTransition(
          scale: TweenSequence<double>([
            TweenSequenceItem(tween: Tween(begin: 1, end: 1.18), weight: 35),
            TweenSequenceItem(tween: Tween(begin: 1.18, end: 1), weight: 65),
          ]).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeOut)),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 5 : 6,
              vertical: widget.compact ? 2 : 3,
            ),
            decoration: BoxDecoration(
              color: theme.surfaceAlt,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: theme.turnHighlight.withValues(alpha: .55),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  coinIcon,
                  size: size,
                  color: theme.turnHighlight,
                ),
                const SizedBox(width: 3),
                Text(
                  '$_shown',
                  style: theme.caption.copyWith(
                    fontSize: size,
                    fontWeight: FontWeight.w800,
                    color: theme.turnHighlight,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_gain > 0)
          Positioned(
            top: -22,
            child: FadeTransition(
              opacity: TweenSequence<double>([
                TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 18),
                TweenSequenceItem(tween: ConstantTween(1), weight: 42),
                TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 40),
              ]).animate(_pop),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.35),
                  end: const Offset(0, -0.8),
                ).animate(
                  CurvedAnimation(parent: _pop, curve: Curves.easeOutCubic),
                ),
                child: CurrencyDeltaLabel(delta: _gain),
              ),
            ),
          ),
      ],
    );
  }
}
