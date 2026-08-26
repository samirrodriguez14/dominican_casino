import 'package:dominican_casino/models/journey.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/journey_worlds.dart';
import 'package:flutter/cupertino.dart';

/// Challenger taunt shown after a Journey challenge loss.
Future<void> showJourneyLossTaunt(
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
                'Try again next time, kid.',
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
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}
