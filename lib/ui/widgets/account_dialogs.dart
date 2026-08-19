import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

enum LinkAccountProvider { google, apple }

bool get appleSignInAvailable =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS);

VoidCallback _soundTap(VoidCallback action) {
  return SoundService.wrapTap(action) ?? action;
}

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

Future<bool> confirmConnectApple(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final go = await showCupertinoDialog<bool>(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      title: Text(l10n.connectApple),
      content: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(l10n.connectAppleWarning),
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

Future<LinkAccountProvider?> pickLinkAccountProvider(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  if (!appleSignInAvailable) {
    return Future.value(LinkAccountProvider.google);
  }
  return showCupertinoModalPopup<LinkAccountProvider>(
    context: context,
    builder: (ctx) => CupertinoActionSheet(
      title: Text(l10n.connectAccountTitle),
      message: Text(l10n.connectAccountBody),
      actions: [
        CupertinoActionSheetAction(
          onPressed: _soundTap(
            () => Navigator.pop(ctx, LinkAccountProvider.google),
          ),
          child: Text(l10n.connectGoogle),
        ),
        CupertinoActionSheetAction(
          onPressed: _soundTap(
            () => Navigator.pop(ctx, LinkAccountProvider.apple),
          ),
          child: Text(l10n.connectApple),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: _soundTap(() => Navigator.pop(ctx)),
        child: Text(l10n.cancel),
      ),
    ),
  );
}

Future<GoogleAuthResult> linkAccountWithPicker(
  BuildContext context,
  AppRepo repo,
) async {
  final provider = await pickLinkAccountProvider(context);
  if (!context.mounted || provider == null) {
    return const GoogleAuthResult.canceled();
  }
  switch (provider) {
    case LinkAccountProvider.google:
      if (!await confirmConnectGoogle(context)) {
        return const GoogleAuthResult.canceled();
      }
      return repo.linkGoogleAccount();
    case LinkAccountProvider.apple:
      if (!await confirmConnectApple(context)) {
        return const GoogleAuthResult.canceled();
      }
      return repo.linkAppleAccount();
  }
}

Future<bool> ensureLinkedAccount(
  BuildContext context, {
  required String title,
  required String body,
}) async {
  final repo = context.read<AppRepo>();
  if (repo.isLinkedAccount) return true;
  final l10n = AppLocalizations.of(context);
  final connect = await showCupertinoDialog<bool>(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      title: Text(title),
      content: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text('$body\n\n${l10n.connectAccountBody}'),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: SoundService.wrapTap(() => Navigator.pop(ctx, false)),
          child: Text(l10n.cancel),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: SoundService.wrapTap(() => Navigator.pop(ctx, true)),
          child: Text(l10n.connectAccountTitle),
        ),
      ],
    ),
  );
  if (connect != true || !context.mounted) return false;

  final result = await linkAccountWithPicker(context, repo);
  if (!context.mounted) return false;
  if (result.status == GoogleAuthStatus.canceled) return false;
  if (result.status == GoogleAuthStatus.failed) {
    await showLinkAccountError(context, result.errorCode);
    return false;
  }
  return context.read<AppRepo>().isLinkedAccount;
}

Future<void> showLinkAccountError(BuildContext context, String? code) async {
  final l10n = AppLocalizations.of(context);
  await showCupertinoDialog<void>(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      title: Text(l10n.connectAccountTitle),
      content: Text(l10n.linkAccountError(code)),
      actions: [
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: SoundService.wrapTap(() => Navigator.pop(ctx)),
          child: Text(l10n.back),
        ),
      ],
    ),
  );
}
