import 'package:dominican_casino/models/journey.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/journey_worlds.dart';
import 'package:flutter/cupertino.dart';

/// Choice from the Journey loss taunt dialog.
enum JourneyLossAction {
  /// Play the same challenger again; story progress stays.
  replay,

  /// Wipe kingdom progress and return to the Diamonds Jack intro.
  restartDiamonds,
}

/// Challenger taunt shown after a Journey challenge loss.
Future<JourneyLossAction?> showJourneyLossTaunt(
  BuildContext context, {
  required JourneyCardDef card,
}) {
  final palette = journeyPaletteFor(card.world);
  return showCupertinoDialog<JourneyLossAction>(
    context: context,
    builder: (ctx) {
      return CupertinoAlertDialog(
        title: Text(card.title),
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
                          card.rank.label,
                          style: TextStyle(color: palette.text),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Haha, you didn\'t stand a chance, kiddo. Give me that mask…',
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
            child: const Text('Replay'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: SoundService.wrapTap(
              () => Navigator.of(ctx).pop(JourneyLossAction.restartDiamonds),
            ),
            child: const Text('Back to Diamonds'),
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
  return showCupertinoDialog<void>(
    context: context,
    builder: (ctx) {
      return CupertinoAlertDialog(
        title: Text(card.title),
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
                          card.rank.label,
                          style: TextStyle(color: palette.text),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Good job. It seems you haven\'t lost your touch.',
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
            child: const Text('Thanks'),
          ),
        ],
      );
    },
  );
}
