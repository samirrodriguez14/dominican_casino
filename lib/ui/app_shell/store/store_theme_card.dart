import 'package:dominican_casino/models/theme_pack.dart';
import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/cards/playing_card_back.dart';
import 'package:dominican_casino/ui/widgets/player_avatar.dart';
import 'package:dominican_casino/ui/widgets/theme_lock_cover.dart';
import 'package:flutter/cupertino.dart';

/// Coin-locked theme pack for sale, painted in that pack's table colors.
class StoreThemeCard extends StatelessWidget {
  const StoreThemeCard({
    super.key,
    required this.pack,
    this.onTap,
  });

  final ThemePack pack;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final packTheme = themeFromEnum(pack.id);
    final ink = packTheme.textPrimary;
    final avatars = [pack.starterAvatarId];

    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: SoundService.wrapTap(onTap),
      child: AspectRatio(
        aspectRatio: 2.5 / 3.5,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: packTheme.pickerFace,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ink.withValues(alpha: .14), width: 1),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.black.withValues(alpha: .30),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
                  child: Column(
                    children: [
                      Text(
                        themeLabel(pack.id),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: packTheme.title.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.05,
                          color: ink,
                        ),
                      ),
                      const Spacer(),
                      if (avatars.isNotEmpty)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var i = 0; i < avatars.length; i++) ...[
                              if (i > 0) const SizedBox(width: 4),
                              PlayerAvatarView(
                                avatarId: avatars[i],
                                size: 22,
                                showBorder: true,
                              ),
                            ],
                          ],
                        ),
                      const SizedBox(height: 8),
                      PlayingCardBack(
                        width: 28,
                        tintId: pack.defaultTintId,
                        mark: CardBackMark.logo,
                        avatarId: pack.starterAvatarId,
                        previewTheme: packTheme,
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
                Positioned.fill(
                  child: ThemeLockCover(coinCost: pack.coinCost),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
