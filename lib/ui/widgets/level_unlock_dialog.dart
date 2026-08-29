import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/l10n/journey_l10n.dart';
import 'package:dominican_casino/services/haptics.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/style/journey_worlds.dart';
import 'package:dominican_casino/style/layouts/app_popup.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Material;

enum LevelUnlockAction { exit, rewards, journey }

/// Custom level-up card: Rewards always; Journey when a kingdom gate opens.
Future<LevelUnlockAction> showLevelUnlockDialog(
  BuildContext context, {
  required int level,
  JourneyWorld? journeyWorld,
  bool showJourneyCta = false,
}) async {
  AppHaptics.mediumImpact();
  SoundService.instance.play(GameSound.win);
  final result = await showAppCenterPopup<LevelUnlockAction>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => _LevelUnlockCard(
      level: level,
      journeyWorld: journeyWorld,
      showJourneyCta: showJourneyCta || journeyWorld != null,
    ),
  );
  return result ?? LevelUnlockAction.exit;
}

class _LevelUnlockCard extends StatelessWidget {
  const _LevelUnlockCard({
    required this.level,
    required this.journeyWorld,
    required this.showJourneyCta,
  });

  final int level;
  final JourneyWorld? journeyWorld;
  final bool showJourneyCta;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final l10n = AppLocalizations.of(context);
    final body = journeyWorld == null
        ? l10n.levelReachedBody
        : l10n.levelReachedBodyWithJourney(
            JourneyL10n.of(context).worldLabel(journeyWorld!),
          );

    return Material(
      color: CupertinoColors.transparent,
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
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.xp.withValues(alpha: .18),
                    border: Border.all(
                      color: theme.xp.withValues(alpha: .55),
                      width: 1.4,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$level',
                    style: theme.title.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: theme.xp,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.levelReachedTitle(level),
                  textAlign: TextAlign.center,
                  style: theme.title.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: theme.body.copyWith(height: 1.4),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    color: theme.textPrimary.withValues(alpha: .18),
                    borderRadius: BorderRadius.circular(12),
                    onPressed: SoundService.wrapTap(
                      () => Navigator.pop(
                        context,
                        LevelUnlockAction.rewards,
                      ),
                    ),
                    child: Text(
                      l10n.goToRewards,
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                if (showJourneyCta) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      color: theme.surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                      onPressed: SoundService.wrapTap(
                        () => Navigator.pop(
                          context,
                          LevelUnlockAction.journey,
                        ),
                      ),
                      child: Text(
                        l10n.goToJourney,
                        style: TextStyle(
                          color: theme.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  onPressed: SoundService.wrapTap(
                    () => Navigator.pop(context, LevelUnlockAction.exit),
                  ),
                  child: Text(
                    l10n.exit,
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
    );
  }
}
