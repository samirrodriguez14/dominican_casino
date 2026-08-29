import 'package:dominican_casino/l10n/journey_l10n.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/journey_worlds.dart';
import 'package:flutter/cupertino.dart';

/// Confirm before switching the app theme to a Journey kingdom pack.
Future<bool> confirmEnterKingdom(
  BuildContext context, {
  required JourneyWorld world,
}) async {
  final j = JourneyL10n.of(context);
  final result = await showCupertinoDialog<bool>(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      title: Text(j.enteringKingdomTitle(world)),
      content: Text(j.enteringKingdomBody(world)),
      actions: [
        CupertinoDialogAction(
          onPressed: SoundService.wrapTap(() => Navigator.pop(ctx, false)),
          child: Text(j.stayHere),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: SoundService.wrapTap(() => Navigator.pop(ctx, true)),
          child: Text(j.continueLabel),
        ),
      ],
    ),
  );
  return result == true;
}

/// Confirm leaving a defeated browse and returning to the progress kingdom.
Future<bool> confirmReturnToProgressKingdom(
  BuildContext context, {
  required JourneyWorld world,
}) async {
  final j = JourneyL10n.of(context);
  final result = await showCupertinoDialog<bool>(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      title: Text(j.returnToKingdomTitle(world)),
      content: Text(j.returnToKingdomBody(world)),
      actions: [
        CupertinoDialogAction(
          onPressed: SoundService.wrapTap(() => Navigator.pop(ctx, false)),
          child: Text(j.keepBrowsing),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: SoundService.wrapTap(() => Navigator.pop(ctx, true)),
          child: Text(j.returnLabel),
        ),
      ],
    ),
  );
  return result == true;
}
