import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/widgets/player_avatar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Material;

Future<String?> showAvatarPickerPopup(
  BuildContext context, {
  String? selectedId,
}) {
  final theme = AppStyle.theme;
  final l10n = AppLocalizations.of(context);

  return showGeneralDialog<String>(
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
            width: 320,
            margin: const EdgeInsets.symmetric(horizontal: 28),
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
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
                  l10n.chooseAvatar,
                  textAlign: TextAlign.center,
                  style: theme.title.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    for (final option in PlayerAvatars.all)
                      GestureDetector(
                        onTap: SoundService.wrapTap(
                          () => Navigator.pop(dialogContext, option.id),
                        ),
                        child: Center(
                          child: PlayerAvatarView(
                            avatarId: option.id,
                            size: 56,
                            selected:
                                option.id ==
                                (selectedId ?? PlayerAvatars.defaultId),
                          ),
                        ),
                      ),
                  ],
                ),
                CupertinoButton(
                  padding: const EdgeInsets.only(top: 8),
                  onPressed: SoundService.wrapTap(
                    () => Navigator.pop(dialogContext),
                  ),
                  child: Text(
                    l10n.cancel,
                    style: TextStyle(color: theme.muted),
                  ),
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
  );
}
