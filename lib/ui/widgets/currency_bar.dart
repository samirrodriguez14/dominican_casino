import 'dart:async';

import 'package:dominican_casino/models/wallet_config.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/services/haptics.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/widgets/coin_icon.dart';
import 'package:dominican_casino/ui/widgets/currency_delta_label.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

/// Compact coins + energy chips for the top of shell screens.
class CurrencyBar extends StatefulWidget {
  const CurrencyBar({super.key, this.compact = true});

  final bool compact;

  static final energyChipKey = GlobalKey(debugLabel: 'energyChip');
  static final coinsChipKey = GlobalKey(debugLabel: 'coinsChip');

  static Offset? centerOf(GlobalKey key) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(box.size.center(Offset.zero));
  }

  static String formatCountdown(Duration remaining) {
    final total = remaining.inSeconds.clamp(0, 3599);
    final m = total ~/ 60;
    final s = total % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  State<CurrencyBar> createState() => _CurrencyBarState();
}

class _CurrencyBarState extends State<CurrencyBar>
    with TickerProviderStateMixin {
  Timer? _timer;
  late final AnimationController _coinsPulse;
  late final AnimationController _energyPulse;
  late final AnimationController _coinsCount;
  late final AnimationController _energyCount;
  late final AnimationController _coinGainPop;

  int _shownCoins = 0;
  int _shownEnergy = 0;
  int _fromCoins = 0;
  int _fromEnergy = 0;
  int _toCoins = 0;
  int _toEnergy = 0;
  int _coinDelta = 0;
  bool _hydrated = false;

  @override
  void initState() {
    super.initState();
    _coinsPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _energyPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _coinsCount = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..addListener(() {
        setState(() {
          _shownCoins = _lerpInt(_fromCoins, _toCoins, _coinsCount.value);
        });
      });
    _energyCount = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..addListener(() {
        setState(() {
          _shownEnergy = _lerpInt(_fromEnergy, _toEnergy, _energyCount.value);
        });
      });
    _coinGainPop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _coinsPulse.dispose();
    _energyPulse.dispose();
    _coinsCount.dispose();
    _energyCount.dispose();
    _coinGainPop.dispose();
    super.dispose();
  }

  int _lerpInt(int a, int b, double t) {
    return a + ((b - a) * Curves.easeOutCubic.transform(t)).round();
  }

  void _syncWallet(int coins, int energy) {
    final gainedCoins = coins > _toCoins;
    final spentCoins = coins < _toCoins;
    final gainedEnergy = energy > _toEnergy;
    if (coins != _toCoins) {
      _fromCoins = _shownCoins;
      _toCoins = coins;
      _coinDelta = coins - _fromCoins;
      _coinsCount.forward(from: 0);
      if (_coinDelta != 0) {
        _coinGainPop.forward(from: 0);
      }
      if (gainedCoins) {
        _coinsPulse.forward(from: 0);
        AppHaptics.mediumImpact();
        SoundService.instance.play(GameSound.coin);
      } else if (spentCoins) {
        AppHaptics.lightImpact();
      }
    }
    if (energy != _toEnergy) {
      final jump = energy - _toEnergy;
      _fromEnergy = _shownEnergy;
      _toEnergy = energy;
      _energyCount.forward(from: 0);
      if (gainedEnergy && jump > 1) {
        _energyPulse.forward(from: 0);
        AppHaptics.lightImpact();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<AppRepo>().wallet;
    if (!_hydrated) {
      _hydrated = true;
      _shownCoins = _fromCoins = _toCoins = wallet.coins;
      _shownEnergy = _fromEnergy = _toEnergy = wallet.energy;
    } else if (wallet.coins != _toCoins || wallet.energy != _toEnergy) {
      final coins = wallet.coins;
      final energy = wallet.energy;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncWallet(coins, energy);
      });
    }

    final theme = AppStyle.theme;
    final compact = widget.compact;
    final padH = compact ? 10.0 : 14.0;
    final padV = compact ? 6.0 : 8.0;
    final iconSize = compact ? 16.0 : 20.0;
    final fontSize = compact ? 13.0 : 16.0;
    final showTimer = wallet.energy < WalletConfig.energyCap;
    final remaining = wallet.timeToNextEnergy();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onLongPress: kDebugMode
              ? () async {
                  AppHaptics.mediumImpact();
                  await context.read<AppRepo>().testEnergyFullNotification();
                }
              : null,
          child: _Chip(
            key: CurrencyBar.energyChipKey,
            icon: CupertinoIcons.bolt_fill,
            value: _shownEnergy,
            color: theme.warning,
            padH: padH,
            padV: padV,
            iconSize: iconSize,
            fontSize: fontSize,
            pulse: _energyPulse,
            suffix: showTimer ? CurrencyBar.formatCountdown(remaining) : null,
          ),
        ),
        const SizedBox(width: 8),
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            _Chip(
              key: CurrencyBar.coinsChipKey,
              icon: coinIcon,
              value: _shownCoins,
              color: theme.turnHighlight,
              padH: padH,
              padV: padV,
              iconSize: iconSize,
              fontSize: fontSize,
              pulse: _coinsPulse,
            ),
            if (_coinDelta != 0)
              Positioned(
                top: _coinDelta > 0 ? -22 : null,
                bottom: _coinDelta < 0 ? -22 : null,
                child: FadeTransition(
                  opacity: TweenSequence<double>([
                    TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 20),
                    TweenSequenceItem(tween: ConstantTween(1), weight: 45),
                    TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 35),
                  ]).animate(_coinGainPop),
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(0, _coinDelta > 0 ? 0.4 : -0.35),
                      end: Offset(0, _coinDelta > 0 ? -0.55 : 0.85),
                    ).animate(
                      CurvedAnimation(
                        parent: _coinGainPop,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                    child: CurrencyDeltaLabel(delta: _coinDelta),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    super.key,
    required this.icon,
    required this.value,
    required this.color,
    required this.padH,
    required this.padV,
    required this.iconSize,
    required this.fontSize,
    required this.pulse,
    this.suffix,
  });

  final IconData icon;
  final int value;
  final Color color;
  final double padH;
  final double padV;
  final double iconSize;
  final double fontSize;
  final AnimationController pulse;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    return ScaleTransition(
      scale: TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 1, end: 1.16), weight: 35),
        TweenSequenceItem(tween: Tween(begin: 1.16, end: 1), weight: 65),
      ]).animate(CurvedAnimation(parent: pulse, curve: Curves.easeOut)),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: theme.border.withValues(alpha: .6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: iconSize, color: color),
            const SizedBox(width: 6),
            Text(
              '$value',
              style: theme.title.copyWith(fontSize: fontSize),
            ),
            if (suffix != null) ...[
              const SizedBox(width: 6),
              Text(
                suffix!,
                style: theme.mutedText.copyWith(
                  fontSize: fontSize - 2,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
