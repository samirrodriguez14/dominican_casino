import 'package:dominican_casino/l10n/app_localizations.dart';
import 'package:dominican_casino/repositories/app_repo.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/widgets/player_avatar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Material;
import 'package:provider/provider.dart';

Future<String?> showAvatarPickerPopup(
  BuildContext context, {
  String? selectedId,
  List<String>? avatarIds,
}) {
  final theme = AppStyle.theme;
  final l10n = AppLocalizations.of(context);
  final ids = (avatarIds == null || avatarIds.isEmpty)
      ? [for (final a in PlayerAvatars.all) a.id]
      : avatarIds;

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
          child: Consumer<AppRepo>(
            builder: (context, repo, _) {
              final wear = repo.wearJourneyAccessories;
              return Container(
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
                      crossAxisCount:
                          ids.length >= 4 ? 4 : ids.length.clamp(1, 3),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      children: [
                        for (final id in ids)
                          GestureDetector(
                            onTap: SoundService.wrapTap(
                              () => Navigator.pop(dialogContext, id),
                            ),
                            child: Center(
                              child: PlayerAvatarView(
                                avatarId: id,
                                size: 56,
                                selected: id ==
                                    (selectedId ?? PlayerAvatars.defaultId),
                                showJourneyAces: true,
                                defeatedAces:
                                    repo.journeyProgress.defeatedAceWorlds,
                                wearJourneyAccessories: wear,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      onPressed: SoundService.wrapTap(() {
                        repo.setWearJourneyAccessories(!wear);
                      }),
                      child: Text(
                        wear ? 'Hide accessories' : 'Show accessories',
                        style: TextStyle(
                          color: theme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.only(top: 0),
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
              );
            },
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondary, child) {
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
      );
    },
  );
}
