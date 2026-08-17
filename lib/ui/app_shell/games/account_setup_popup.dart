import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/widgets/google_g_mark.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Material;
import 'package:provider/provider.dart';

/// After the pre-login tutorial: pick a name, stay guest, or connect Google.
Future<void> showAccountSetupPopup(BuildContext context) {
  final theme = AppStyle.theme;
  final l10n = AppLocalizations.of(context);
  final controller = TextEditingController();

  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: CupertinoColors.black.withValues(alpha: .55),
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return Center(
        child: Material(
          color: CupertinoColors.transparent,
          child: Container(
            width: 300,
            margin: const EdgeInsets.symmetric(horizontal: 28),
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.border.withValues(alpha: .7)),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.black.withValues(alpha: .45),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.saveProgressTitle,
                  textAlign: TextAlign.center,
                  style: theme.title.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.saveProgressBody,
                  textAlign: TextAlign.center,
                  style: theme.body.copyWith(height: 1.4),
                ),
                const SizedBox(height: 18),
                CupertinoTextField(
                  controller: controller,
                  maxLength: 10,
                  textAlign: TextAlign.center,
                  placeholder: l10n.yourName,
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        color: theme.surfaceAlt,
                        borderRadius: BorderRadius.circular(12),
                        onPressed: () async {
                          await _saveName(dialogContext, controller.text);
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.person,
                              size: 16,
                              color: theme.textPrimary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              l10n.guest,
                              style: TextStyle(
                                color: theme.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        color: theme.surfaceRaised,
                        borderRadius: BorderRadius.circular(12),
                        onPressed: () async {
                          await _saveName(dialogContext, controller.text);
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const GoogleGMark(size: 15),
                            const SizedBox(width: 6),
                            Text(
                              l10n.google,
                              style: TextStyle(
                                color: theme.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                CupertinoButton(
                  padding: const EdgeInsets.only(top: 4),
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(l10n.later, style: TextStyle(color: theme.muted)),
                ),
              ],
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondary, child) {
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          child: child,
        ),
      );
    },
  ).whenComplete(controller.dispose);
}

Future<void> _saveName(BuildContext context, String raw) async {
  final name = raw.trim();
  if (name.isEmpty) return;
  await context.read<AppRepo>().updatePlayer(name);
}
