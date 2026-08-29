import 'package:dominican_casino/l10n/journey_l10n.dart';
import 'package:dominican_casino/models/journey.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/journey_worlds.dart';
import 'package:flutter/cupertino.dart';

/// Choice from the Journey loss taunt dialog.
enum JourneyLossAction {
  /// Play the same challenger again; story progress stays.
  replay,

  /// Wipe this kingdom (and later ones) and return to its entrance.
  restartKingdom,
}

/// Challenger taunt shown after a Journey challenge loss (or Spades Jack camp deny).
Future<JourneyLossAction?> showJourneyLossTaunt(
  BuildContext context, {
  required JourneyCardDef card,
  String? message,
}) {
  final palette = journeyPaletteFor(card.world);
  final j = JourneyL10n.of(context);
  final kingdomLabel = j.worldLabel(card.world);
  return showCupertinoDialog<JourneyLossAction>(
    context: context,
    builder: (ctx) {
      return CupertinoAlertDialog(
        title: Text(j.cardTitle(card)),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: ColoredBox(
                  color: palette.surface,
                  child: Image.asset(
                    card.avatarAssetPath,
                    height: 140,
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomCenter,
                    errorBuilder: (_, _, _) => SizedBox(
                      height: 140,
                      width: 100,
                      child: Center(
                        child: Text(
                          j.rankLabel(card.rank),
                          style: TextStyle(color: palette.text),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                message ?? j.lossTauntDefault,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: palette.text.withValues(alpha: 0.9),
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: SoundService.wrapTap(
              () => Navigator.of(ctx).pop(JourneyLossAction.replay),
            ),
            child: Text(j.replay),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: SoundService.wrapTap(
              () => Navigator.of(ctx).pop(JourneyLossAction.restartKingdom),
            ),
            child: Text(j.backToKingdom(kingdomLabel)),
          ),
        ],
      );
    },
  );
}

/// Praise after beating an already-defeated challenger again.
Future<void> showJourneyReplayPraise(
  BuildContext context, {
  required JourneyCardDef card,
}) {
  final palette = journeyPaletteFor(card.world);
  final j = JourneyL10n.of(context);
  return showCupertinoDialog<void>(
    context: context,
    builder: (ctx) {
      return CupertinoAlertDialog(
        title: Text(j.cardTitle(card)),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: ColoredBox(
                  color: palette.surface,
                  child: Image.asset(
                    card.avatarAssetPath,
                    height: 140,
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomCenter,
                    errorBuilder: (_, _, _) => SizedBox(
                      height: 140,
                      width: 100,
                      child: Center(
                        child: Text(
                          j.rankLabel(card.rank),
                          style: TextStyle(color: palette.text),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                j.replayPraise,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: palette.text.withValues(alpha: 0.9),
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: SoundService.wrapTap(() => Navigator.of(ctx).pop()),
            child: Text(j.thanks),
          ),
        ],
      );
    },
  );
}
