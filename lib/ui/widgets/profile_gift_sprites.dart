import 'package:dominican_casino/style/app_theme.dart';
import 'package:dominican_casino/style/journey_worlds.dart';
import 'package:dominican_casino/ui/widgets/player_avatar.dart';
import 'package:flutter/cupertino.dart';

/// Compact gift sprites that fly into the Profile tab.
class ProfileGiftSprites {
  static Widget themeBadge(JourneyWorld world, {double size = 72}) {
    final palette = journeyPaletteFor(world);
    return Container(
      width: size * 0.75,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.accent, width: 1.6),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.surface, palette.background],
        ),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: .28),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        world.suitSymbol,
        style: TextStyle(
          color: palette.accent,
          fontSize: size * 0.36,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  static Widget leagueBadge(JourneyWorld world, {double size = 64}) {
    final palette = journeyPaletteFor(world);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: palette.accent, width: 1.6),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.surface, palette.background],
        ),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: .28),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(
        CupertinoIcons.rosette,
        color: palette.accent,
        size: size * 0.42,
      ),
    );
  }

  static Widget themeAndLeague(JourneyWorld world) {
    return SizedBox(
      width: 120,
      height: 90,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            child: themeBadge(world, size: 70),
          ),
          Positioned(
            right: 0,
            child: leagueBadge(world, size: 58),
          ),
        ],
      ),
    );
  }

  static Widget avatar(String avatarId, {double size = 72}) {
    final theme = AppStyle.theme;
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: .28),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: theme.textPrimary.withValues(alpha: .2),
          width: 2,
        ),
      ),
      child: PlayerAvatarView(
        avatarId: avatarId,
        size: size,
        showBorder: true,
      ),
    );
  }
}
