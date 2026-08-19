import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:flutter/cupertino.dart';

Future<bool> confirmConnectGoogle(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final go = await showCupertinoDialog<bool>(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      title: Text(l10n.connectGoogle),
      content: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(l10n.connectGoogleWarning),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: SoundService.wrapTap(() => Navigator.pop(ctx, false)),
          child: Text(l10n.cancel),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: SoundService.wrapTap(() => Navigator.pop(ctx, true)),
          child: Text(l10n.continueLabel),
        ),
      ],
    ),
  );
  return go ?? false;
}
