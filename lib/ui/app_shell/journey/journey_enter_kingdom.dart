import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/journey_worlds.dart';
import 'package:flutter/cupertino.dart';

/// Confirm before switching the app theme to a Journey kingdom pack.
Future<bool> confirmEnterKingdom(
  BuildContext context, {
  required JourneyWorld world,
}) async {
  final result = await showCupertinoDialog<bool>(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      title: Text('Entering ${world.label}'),
      content: Text(
        'You are entering the ${world.label} kingdom. '
        'This will change the theme of the application.',
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: SoundService.wrapTap(() => Navigator.pop(ctx, false)),
          child: const Text('Stay here'),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: SoundService.wrapTap(() => Navigator.pop(ctx, true)),
          child: const Text('Continue'),
        ),
      ],
    ),
  );
  return result == true;
}
