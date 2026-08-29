import 'package:dominican_casino/l10n/journey_l10n.dart';
import 'package:dominican_casino/services/haptics.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/style/journey_worlds.dart';
import 'package:flutter/cupertino.dart';

/// Post-ceremony reward: theme + league unlocked, with Go to profile or Continue.
class JourneyThemeUnlockRewardOverlay extends StatefulWidget {
  const JourneyThemeUnlockRewardOverlay({
    super.key,
    required this.world,
    required this.onGoToProfile,
    required this.onContinue,
  });

  final JourneyWorld world;
  final VoidCallback onGoToProfile;
  final VoidCallback onContinue;

  @override
  State<JourneyThemeUnlockRewardOverlay> createState() =>
      _JourneyThemeUnlockRewardOverlayState();
}

class _JourneyThemeUnlockRewardOverlayState
    extends State<JourneyThemeUnlockRewardOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _in;
  bool _started = false;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _in = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    if (_started || !mounted) return;
    _started = true;
    AppHaptics.mediumImpact();
    SoundService.instance.play(GameSound.win);
    await _in.forward();
  }

  Future<void> _dismiss({required bool goToProfile}) async {
    if (!mounted || _closing) return;
    _closing = true;
    await _in.reverse();
    if (!mounted) return;
    if (goToProfile) {
      widget.onGoToProfile();
    } else {
      widget.onContinue();
    }
  }

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final palette = journeyPaletteFor(widget.world);
    final j = JourneyL10n.of(context);

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
              scale: Tween<double>(begin: 0.88, end: 1).animate(
                CurvedAnimation(parent: _in, curve: Curves.easeOutBack),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.textPrimary.withValues(alpha: .16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: CupertinoColors.black.withValues(alpha: .28),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          j.themeAndLeagueUnlocked,
                          textAlign: TextAlign.center,
                          style: theme.title.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          j.worldThemeAndLeagueUnlocked(widget.world),
                          textAlign: TextAlign.center,
                          style: theme.mutedText,
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _RewardBadge(
                              symbol: widget.world.suitSymbol,
                              label: j.worldThemeLabel(widget.world),
                              palette: palette,
                              theme: theme,
                            ),
                            const SizedBox(width: 14),
                            _RewardBadge(
                              symbol: widget.world.suitSymbol,
                              label: j.worldLeagueLabel(widget.world),
                              palette: palette,
                              theme: theme,
                              league: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 12,
                          ),
                          color: theme.textPrimary.withValues(alpha: .18),
                          borderRadius: BorderRadius.circular(12),
                          onPressed: SoundService.wrapTap(
                            () => _dismiss(goToProfile: true),
                          ),
                          child: Text(
                            j.goToProfile,
                            style: TextStyle(
                              color: theme.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 8,
                          ),
                          onPressed: SoundService.wrapTap(
                            () => _dismiss(goToProfile: false),
                          ),
                          child: Text(
                            j.continueLabel,
                            style: TextStyle(
                              color: theme.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardBadge extends StatelessWidget {
  const _RewardBadge({
    required this.symbol,
    required this.label,
    required this.palette,
    required this.theme,
    this.league = false,
  });

  final String symbol;
  final String label;
  final JourneyWorldPalette palette;
  final AppTheme theme;
  final bool league;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: league ? 64 : 84,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(league ? 999 : 12),
            color: palette.background,
            border: Border.all(color: palette.accent, width: 1.4),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [palette.surface, palette.background],
            ),
          ),
          alignment: Alignment.center,
          child: league
              ? Icon(
                  CupertinoIcons.rosette,
                  color: palette.accent,
                  size: 28,
                )
              : Text(
                  symbol,
                  style: TextStyle(
                    color: palette.accent,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 120,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.body.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
