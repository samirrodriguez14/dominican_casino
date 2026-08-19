import 'dart:async';

import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/services/haptics.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/animations/currency_burst.dart';
import 'package:dominican_casino/ui/widgets/currency_bar.dart';
import 'package:flutter/cupertino.dart';

/// Energy congrats card, then energy icon jumps into the top-right stack.
class HomeEnergyCelebrationOverlay extends StatefulWidget {
  const HomeEnergyCelebrationOverlay({
    super.key,
    required this.amount,
    required this.onCollected,
    required this.onDismissed,
  });

  final int amount;
  final Future<void> Function() onCollected;
  final VoidCallback onDismissed;

  @override
  State<HomeEnergyCelebrationOverlay> createState() =>
      _HomeEnergyCelebrationOverlayState();
}

class _HomeEnergyCelebrationOverlayState
    extends State<HomeEnergyCelebrationOverlay>
    with SingleTickerProviderStateMixin {
  final _amountKey = GlobalKey();
  late final AnimationController _in;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _in = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    if (_started || !mounted) return;
    _started = true;
    AppHaptics.mediumImpact();
    SoundService.instance.play(GameSound.win);
    await _in.forward();
    await Future<void>.delayed(const Duration(milliseconds: 520));
    if (!mounted) return;

    final from = CurrencyBar.centerOf(_amountKey);
    final to = CurrencyBar.centerOf(CurrencyBar.energyChipKey);
    if (from != null && to != null) {
      await CurrencyBurst.play(
        context: context,
        from: from,
        to: to,
        icon: CupertinoIcons.bolt_fill,
        color: AppStyle.theme.turnHighlight,
        count: widget.amount.clamp(4, 12),
        jump: true,
      );
    }

    if (!mounted) return;
    await widget.onCollected();
    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (!mounted) return;
    await _in.reverse();
    if (!mounted) return;
    widget.onDismissed();
  }

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final l10n = AppLocalizations.of(context);
    return FadeTransition(
      opacity: CurvedAnimation(parent: _in, curve: Curves.easeOut),
      child: Stack(
        children: [
          Positioned.fill(
            child: ModalBarrier(
              color: CupertinoColors.black.withValues(alpha: .45),
              dismissible: false,
            ),
          ),
          Center(
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.86, end: 1).animate(
                CurvedAnimation(parent: _in, curve: Curves.easeOutBack),
              ),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 36),
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                decoration: BoxDecoration(
                  color: theme.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: theme.turnHighlight.withValues(alpha: .55),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.black.withValues(alpha: .35),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.energyCongratsTitle,
                      textAlign: TextAlign.center,
                      style: theme.title.copyWith(fontSize: 22),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.energyCongratsBody(widget.amount),
                      textAlign: TextAlign.center,
                      style: theme.body,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      key: _amountKey,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.bolt_fill,
                          size: 28,
                          color: theme.turnHighlight,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.amount}',
                          style: theme.title.copyWith(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: theme.turnHighlight,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

