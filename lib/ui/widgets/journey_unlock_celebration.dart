import 'package:dominican_casino/models/journey_progress.dart';
import 'package:dominican_casino/services/haptics.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/widgets/player_avatar.dart';
import 'package:flutter/cupertino.dart';

/// Post-match unlock card: Journey avatar and/or newly unlocked theme.
class JourneyUnlockCelebrationOverlay extends StatefulWidget {
  const JourneyUnlockCelebrationOverlay({
    super.key,
    required this.reward,
    required this.onDismissed,
  });

  final JourneyUnlockReward reward;
  final VoidCallback onDismissed;

  @override
  State<JourneyUnlockCelebrationOverlay> createState() =>
      _JourneyUnlockCelebrationOverlayState();
}

class _JourneyUnlockCelebrationOverlayState
    extends State<JourneyUnlockCelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _in;
  bool _started = false;

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

  Future<void> _dismiss() async {
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
    final reward = widget.reward;
    final avatarId = reward.avatarId;
    Theme? unlockedTheme;
    if (reward.themeId != null) {
      for (final value in Theme.values) {
        if (value.name == reward.themeId) {
          unlockedTheme = value;
          break;
        }
      }
    }
    final themeLabel = unlockedTheme == null
        ? null
        : switch (unlockedTheme) {
            Theme.casino => 'Diamonds',
            Theme.dune => 'Clubs',
            Theme.fig => 'Hearts',
            Theme.midnight => 'Spades',
            Theme.sage => 'Base',
          };

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
                          'Unlocked',
                          style: theme.title.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'New rewards from your victory.',
                          textAlign: TextAlign.center,
                          style: theme.mutedText,
                        ),
                        if (avatarId != null) ...[
                          const SizedBox(height: 18),
                          PlayerAvatarView(
                            avatarId: avatarId,
                            size: 72,
                            showBorder: true,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${reward.rank.label} avatar',
                            style: theme.body.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                        if (themeLabel != null) ...[
                          const SizedBox(height: 16),
                          Icon(
                            CupertinoIcons.paintbrush_fill,
                            size: 28,
                            color: theme.turnHighlight,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$themeLabel theme',
                            style: theme.body.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 12,
                          ),
                          color: theme.textPrimary.withValues(alpha: .14),
                          borderRadius: BorderRadius.circular(12),
                          onPressed: SoundService.wrapTap(_dismiss),
                          child: Text(
                            'Continue',
                            style: TextStyle(
                              color: theme.textPrimary,
                              fontWeight: FontWeight.w700,
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
