import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

Future<void> showInsufficientFundsDialog(
  BuildContext context, {
  required bool energy,
}) async {
  final l10n = AppLocalizations.of(context);
  final goStore = await showCupertinoDialog<bool>(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      title: Text(energy ? l10n.notEnoughEnergy : l10n.notEnoughCoins),
      content: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          energy ? l10n.notEnoughEnergyBody : l10n.notEnoughCoinsBody,
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: SoundService.wrapTap(() => Navigator.of(ctx).pop(false)),
          child: Text(l10n.cancel),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: SoundService.wrapTap(() => Navigator.of(ctx).pop(true)),
          child: Text(
            l10n.goToStore,
            style: AppStyle.theme.title,
          ),
        ),
      ],
    ),
  );
  if (goStore == true && context.mounted) {
    goToStoreTab(context);
  }
}

Future<bool> showConfirmStorePurchase(
  BuildContext context, {
  required String body,
}) async {
  final l10n = AppLocalizations.of(context);
  final ok = await showCupertinoDialog<bool>(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      title: Text(l10n.confirmPurchase),
      content: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(body),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: SoundService.wrapTap(() => Navigator.of(ctx).pop(false)),
          child: Text(l10n.cancel),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: SoundService.wrapTap(() => Navigator.of(ctx).pop(true)),
          child: Text(l10n.buy, style: AppStyle.theme.title),
        ),
      ],
    ),
  );
  return ok ?? false;
}

void goToStoreTab(BuildContext context) {
  context.read<AppRepo>().requestShellTab(0);
  final path = GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;
  if (!path.startsWith('/landing')) {
    context.go('/landing');
  }
}
