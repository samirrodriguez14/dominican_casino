import 'package:dominican_casino/services/sound_service.dart';
import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/ui/widgets/coin_gain_badge.dart';
import 'package:dominican_casino/ui/widgets/player_avatar.dart';
import 'package:flutter/cupertino.dart';

/// Avatar with match score at the top-left and pending coins at the bottom-right.
class PlayerScoreAvatar extends StatelessWidget {
  const PlayerScoreAvatar({
    super.key,
    required this.avatarId,
    required this.score,
    required this.pendingCoins,
    this.onPressed,
    this.size = 64,
  });

  final String? avatarId;
  final dynamic score;
  final int pendingCoins;
  final VoidCallback? onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = AppStyle.theme;
    final chipSize = size < 52 ? 10.0 : 11.0;
    final avatar = SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.textPrimary.withValues(alpha: .18),
              ),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.black.withValues(alpha: .28),
                  blurRadius: size * 0.18,
                  offset: Offset(0, size * 0.09),
                ),
              ],
            ),
            child: PlayerAvatarView(
              avatarId: avatarId,
              size: size,
              showBorder: false,
            ),
          ),
          Positioned(
            left: -2,
            top: -2,
            child: Container(
              constraints: const BoxConstraints(minWidth: 22),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.surfaceAlt,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: theme.background, width: 2),
              ),
              alignment: Alignment.center,
              child: Text(
                '$score',
                style: theme.caption.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.textPrimary,
                  fontSize: chipSize,
                ),
              ),
            ),
          ),
          Positioned(
            right: -4,
            bottom: -2,
            child: CoinGainBadge(pending: pendingCoins, compact: size < 56),
          ),
        ],
      ),
    );

    if (onPressed == null) return avatar;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: SoundService.wrapTap(onPressed!),
      child: avatar,
    );
  }
}
